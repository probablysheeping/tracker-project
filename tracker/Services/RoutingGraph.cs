// In-memory routing graph with Yen's k-shortest paths algorithm.
// Replaces pgRouting pgr_KSP, enabling deployment to any PostgreSQL provider
// (Supabase, Neon, Railway, etc.) without requiring pgRouting extension.
using Microsoft.Extensions.Configuration;
using Npgsql;

namespace PTVApp.Services
{
    public class RoutingGraph
    {
        private record Edge(long Target, double Cost, bool IsReplacementBus);

        private readonly Dictionary<long, List<Edge>> _adj = new();
        private readonly Dictionary<int, (double Lat, double Lon)> _stopCoords = new();
        private bool _loaded = false;

        public bool IsLoaded => _loaded;

        public async Task LoadFromConfig(IConfiguration config)
        {
            var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
            string connStr;
            if (!string.IsNullOrEmpty(databaseUrl))
            {
                var uri = new Uri(databaseUrl);
                var userInfo = uri.UserInfo.Split(':');
                connStr = $"Host={uri.Host};Port={uri.Port};Username={userInfo[0]};Password={Uri.UnescapeDataString(userInfo[1])};Database={uri.AbsolutePath.TrimStart('/')};SSL Mode=Require;Trust Server Certificate=true";
            }
            else
            {
                var host = config["Database:Host"] ?? "localhost";
                var port = config.GetValue<int>("Database:Port", 5432);
                var username = config["Database:Username"] ?? "postgres";
                var password = config["Database:Password"] ?? "password";
                var database = config["Database:Database"] ?? "tracker";
                connStr = $"Host={host};Port={port};Username={username};Password={password};Database={database}";
            }
            await LoadAsync(connStr);
        }

        public async Task LoadAsync(string connectionString)
        {
            if (_loaded) return;

            await using var conn = new NpgsqlConnection(connectionString);
            await conn.OpenAsync();

            // Load edges with replacement-bus flag (both directions for undirected graph)
            int edgeCount = 0;
            await using var edgeCmd = new NpgsqlCommand(@"
                SELECT e.source_node, e.target_node, e.cost,
                       COALESCE(r.is_replacement_bus, false)
                FROM edges_v2 e
                LEFT JOIN routes r ON r.route_id = e.source_route
                WHERE e.source_node IS NOT NULL AND e.target_node IS NOT NULL
            ", conn);
            await using (var reader = await edgeCmd.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    var src = reader.GetInt64(0);
                    var tgt = reader.GetInt64(1);
                    var cost = reader.GetDouble(2);
                    var isReplacement = reader.GetBoolean(3);
                    AddEdge(src, tgt, cost, isReplacement);
                    AddEdge(tgt, src, cost, isReplacement); // undirected
                    edgeCount++;
                }
            }

            // Load stop coordinates
            await using var stopCmd = new NpgsqlCommand(
                "SELECT stop_id, stop_latitude, stop_longitude FROM stops", conn);
            await using (var reader = await stopCmd.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                    _stopCoords[reader.GetInt32(0)] = (reader.GetDouble(1), reader.GetDouble(2));
            }

            _loaded = true;
            Console.WriteLine($"[RoutingGraph] Loaded {edgeCount} edges ({_adj.Count} nodes), {_stopCoords.Count} stops");
        }

        private void AddEdge(long source, long target, double cost, bool isReplacement)
        {
            if (!_adj.TryGetValue(source, out var list))
                _adj[source] = list = new List<Edge>();
            list.Add(new Edge(target, cost, isReplacement));
        }

        public (double Lat, double Lon) GetStopCoords(int stopId) =>
            _stopCoords.TryGetValue(stopId, out var c) ? c : (0, 0);

        /// <summary>
        /// Dijkstra shortest path. Returns (total cost, ordered node list).
        /// Returns empty path if unreachable.
        /// </summary>
        private (double Cost, List<long> Path) Dijkstra(
            long source,
            long target,
            HashSet<(long From, long To)>? removedEdges = null,
            HashSet<long>? removedNodes = null,
            bool includeReplacementBuses = true)
        {
            var dist = new Dictionary<long, double> { [source] = 0.0 };
            var prev = new Dictionary<long, long>();
            var pq = new PriorityQueue<long, double>();
            pq.Enqueue(source, 0.0);

            while (pq.Count > 0)
            {
                pq.TryDequeue(out var u, out var uCost);
                if (u == target) break;
                if (uCost > dist.GetValueOrDefault(u, double.MaxValue)) continue;
                if (removedNodes?.Contains(u) == true) continue;
                if (!_adj.TryGetValue(u, out var neighbors)) continue;

                foreach (var edge in neighbors)
                {
                    if (!includeReplacementBuses && edge.IsReplacementBus) continue;
                    if (removedEdges?.Contains((u, edge.Target)) == true) continue;
                    if (removedNodes?.Contains(edge.Target) == true) continue;

                    var newCost = uCost + edge.Cost;
                    if (newCost < dist.GetValueOrDefault(edge.Target, double.MaxValue))
                    {
                        dist[edge.Target] = newCost;
                        prev[edge.Target] = u;
                        pq.Enqueue(edge.Target, newCost);
                    }
                }
            }

            if (!dist.ContainsKey(target))
                return (double.MaxValue, new List<long>());

            var path = new List<long>();
            for (var n = target; prev.ContainsKey(n); n = prev[n])
                path.Add(n);
            path.Add(source);
            path.Reverse();
            return (dist[target], path);
        }

        private double GetEdgeCost(long from, long to)
        {
            if (!_adj.TryGetValue(from, out var edges)) return double.MaxValue;
            foreach (var e in edges)
                if (e.Target == to) return e.Cost;
            return double.MaxValue;
        }

        /// <summary>
        /// Returns the cost of the shortest path between two nodes.
        /// Returns 10.0 (default travel estimate) if unreachable.
        /// </summary>
        public double GetPathCost(long source, long target)
        {
            var (cost, _) = Dijkstra(source, target);
            return (cost == double.MaxValue || cost <= 0) ? 10.0 : cost;
        }

        private static bool PathsShareRoot(List<long> path, List<long> root, int length)
        {
            if (path.Count < length) return false;
            for (int i = 0; i < length; i++)
                if (path[i] != root[i]) return false;
            return true;
        }

        /// <summary>
        /// Yen's k-shortest simple paths algorithm (undirected graph).
        /// Returns up to k paths as ordered lists of (stopId, routeId, lat, lon, aggCost) tuples.
        /// pathId is 1-indexed to match pgr_KSP convention.
        /// </summary>
        public List<List<(int PathId, int StopId, int RouteId, double Lat, double Lon, double AggCost)>> KShortestPaths(
            long source, long target, int k, bool includeReplacementBuses = true)
        {
            // A = confirmed k-shortest paths; B = candidates
            var A = new List<(List<long> path, double cost)>();
            var B = new List<(List<long> path, double cost)>();

            var (c0, p0) = Dijkstra(source, target, includeReplacementBuses: includeReplacementBuses);
            if (p0.Count == 0)
                return new List<List<(int, int, int, double, double, double)>>();

            A.Add((p0, c0));

            for (int ki = 1; ki < k; ki++)
            {
                var prevPath = A[ki - 1].path;

                for (int i = 0; i < prevPath.Count - 1; i++)
                {
                    var spurNode = prevPath[i];
                    var rootPath = prevPath.Take(i + 1).ToList();

                    var removedEdges = new HashSet<(long, long)>();

                    foreach (var (ap, _) in A)
                        if (PathsShareRoot(ap, rootPath, i + 1))
                            removedEdges.Add((ap[i], ap[i + 1]));

                    foreach (var (bp, _) in B)
                        if (PathsShareRoot(bp, rootPath, i + 1))
                            removedEdges.Add((bp[i], bp[i + 1]));

                    // Exclude root path nodes (except spur) to avoid loops
                    var removedNodes = new HashSet<long>(rootPath.Take(rootPath.Count - 1));

                    var (spurCost, spurPath) = Dijkstra(
                        spurNode, target, removedEdges, removedNodes, includeReplacementBuses);
                    if (spurPath.Count == 0) continue;

                    var totalPath = new List<long>(rootPath);
                    totalPath.AddRange(spurPath.Skip(1));

                    double rootCost = 0;
                    for (int j = 0; j < rootPath.Count - 1; j++)
                        rootCost += GetEdgeCost(rootPath[j], rootPath[j + 1]);
                    var totalCost = rootCost + spurCost;

                    if (!A.Any(ap => ap.path.SequenceEqual(totalPath)) &&
                        !B.Any(bp => bp.path.SequenceEqual(totalPath)))
                        B.Add((totalPath, totalCost));
                }

                if (B.Count == 0) break;
                B.Sort((x, y) => x.cost.CompareTo(y.cost));
                A.Add(B[0]);
                B.RemoveAt(0);
            }

            // Convert to the expected output format (matching pgr_KSP result shape)
            var result = new List<List<(int, int, int, double, double, double)>>();
            for (int pathIdx = 0; pathIdx < A.Count; pathIdx++)
            {
                var (path, _) = A[pathIdx];
                var nodes = new List<(int PathId, int StopId, int RouteId, double Lat, double Lon, double AggCost)>();
                double aggCost = 0;

                for (int ni = 0; ni < path.Count; ni++)
                {
                    var node = path[ni];
                    var stopId = (int)(node / 1_000_000_000L);
                    var routeId = (int)(node % 1_000_000_000L);
                    var (lat, lon) = GetStopCoords(stopId);

                    if (ni > 0)
                        aggCost += GetEdgeCost(path[ni - 1], node);

                    nodes.Add((pathIdx + 1, stopId, routeId, lat, lon, aggCost));
                }
                result.Add(nodes);
            }

            return result;
        }
    }
}
