using System.Text.RegularExpressions;
using System.Globalization;
using PTVApp.Models;

namespace PTVApp.Services
{
    public class DisruptionTime
    {
        public TimeOnly? Time { get; set; }
        public DateOnly? Date { get; set; }
        public bool IsLastService { get; set; }

        public DateTime? ToDateTime()
        {
            if (Time.HasValue && Date.HasValue)
            {
                return Date.Value.ToDateTime(Time.Value);
            }
            else if (Time.HasValue)
            {
                // Use today's date if no date specified
                return DateOnly.FromDateTime(DateTime.Today).ToDateTime(Time.Value);
            }
            else if (IsLastService && Date.HasValue)
            {
                // Use 1:30am as placeholder for "last service"
                // This is more accurate than midnight since most weeknight last trains run 12:30am-1:00am
                // Weekend Night Network runs all night (separate handling needed)
                // TODO: Query GTFS data for actual last service time per route/day
                return Date.Value.ToDateTime(new TimeOnly(23, 59, 59));
            }
            return null;
        }
    }

    public partial class DisruptionParser
    {
        public static DisruptionTime? ParseDisruptionTime(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
                return null;

            // Check for special cases
            if (input.Contains("last service", StringComparison.OrdinalIgnoreCase))
            {
                return new DisruptionTime { IsLastService = true };
            }

            // Normalize dots to colons
            input = MyRegex().Replace(input, ":$1");

            // Try to parse time and date together first
            var combined = ParseCombinedTimeDate(input);
            if (combined != null)
                return combined;

            // Try parsing just time
            var time = ParseTimeOnly(input);
            if (time.HasValue)
            {
                return new DisruptionTime { Time = time };
            }

            return null;
        }

        private static DisruptionTime? ParseCombinedTimeDate(string input)
        {
            var formats = new[]
            {
                "h:mmtt dddd d MMMM",      // 10:30pm Saturday 20 December
                "h:mmtt ddd d MMMM",        // 10:30pm Sat 20 December
                "h.mmtt dddd d MMMM",       // 10.30pm Saturday 20 December
                "h.mmtt ddd d MMMM",         // 10.30pm Sat 20 December
                "htt dddd d MMMM",     // 5am Saturday 13 December
                "htt ddd d MMMM"       // 5am Sat 13 December

            };

            foreach (var format in formats)
            {
                if (DateTime.TryParseExact(input, format,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AllowWhiteSpaces,
                    out DateTime result))
                {
                    // Add current year since format doesn't include it
                    var fullDate = new DateTime(DateTime.Now.Year, result.Month, result.Day,
                                               result.Hour, result.Minute, 0);

                    return new DisruptionTime
                    {
                        Time = TimeOnly.FromDateTime(fullDate),
                        Date = DateOnly.FromDateTime(fullDate)
                    };
                }
            }

            return null;
        }

        public static TimeOnly? ParseTimeOnly(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
                return null;

            // Normalize dots to colons
            input = MyRegex().Replace(input, ":$1");

            var formats = new[]
            {
                "h:mmtt",    // 10:30pm
                "h.mmtt",    // 10.30pm
                "htt",       // 6pm
                "h tt"       // 6 pm
            };

            foreach (var format in formats)
            {
                if (TimeOnly.TryParseExact(input, format,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.None,
                    out TimeOnly result))
                {
                    return result;
                }
            }

            return null;
        }

        public static DateOnly? ParseDateOnly(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
                return null;

            var formats = new[]
            {
                "dddd d MMMM",      // Saturday 20 December
                "ddd d MMMM",       // Sat 20 December
                "d MMMM",           // 20 December
                "dddd d MMM",       // Saturday 20 Dec
                "d MMM"             // 20 Dec
            };

            foreach (var format in formats)
            {
                if (DateOnly.TryParseExact(input, format,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.None,
                    out DateOnly result))
                {
                    // Add current year since format doesn't include it
                    return new DateOnly(DateTime.Now.Year, result.Month, result.Day);
                }
            }

            return null;
        }

        private static int MinNonNegative(int a, int b)
        {
            if (a == -1) return b;
            if (b == -1) return a;
            return Math.Min(a, b);
        }

        /// <summary>
        /// Parse time period from text after " from " keyword.
        /// Handles multiple formats:
        /// - "10:30pm Saturday 20 December to 6am Sunday 21 December" (combined time+date, overnight)
        /// - "10:30pm to last service each night, Monday 22 December and Tuesday 23 December" (multi-night)
        /// - "8:30pm to last service each night, Monday 8 December to Wednesday 10 December" (date range)
        /// - "9:00am to 5:00pm Saturday 25 December" (same day)
        /// </summary>
        private static List<DisruptionPeriod> ParseTimePeriod(string text, int fromIdx)
        {
            var periods = new List<DisruptionPeriod>();

            int startIdx = fromIdx + " from ".Length;
            int dividerIdx = text.IndexOf(" to ", startIdx);
            if (dividerIdx == -1) return periods;

            int endIdx = text.IndexOf(", ", dividerIdx);
            if (endIdx == -1) endIdx = text.IndexOf(". ", dividerIdx);
            if (endIdx == -1) endIdx = text.Length;

            // Parse times
            var startTimeStr = text.Substring(startIdx, dividerIdx - startIdx).Trim();
            var endTimeStr = text.Substring(dividerIdx + " to ".Length, endIdx - (dividerIdx + " to ".Length)).Trim();

            var startTime = ParseDisruptionTime(startTimeStr);
            var endTime = ParseDisruptionTime(endTimeStr);
            if (startTime is null || endTime is null) return periods;

            // If both start and end have dates (e.g., "10:30pm Saturday 20 December to 6am Sunday 21 December")
            if (startTime.Date.HasValue && endTime.Date.HasValue)
            {
                periods.Add(new DisruptionPeriod
                {
                    StartDateTime = startTime.ToDateTime(),
                    EndDateTime = endTime.ToDateTime(),
                    IsLastService = endTime.IsLastService
                });
                return periods;
            }

            // Times are separate from dates - need to parse date portion
            // Check if "each night" is mentioned
            bool isEachNight = text.Contains("each night", StringComparison.OrdinalIgnoreCase);

            int mid = MinNonNegative(text.IndexOf(" to ", endIdx), text.IndexOf(" and ", endIdx));
            if (mid == -1) return periods;

            var firstDate = ParseDateOnly(text.Substring(endIdx + ", ".Length, mid - (endIdx + ", ".Length)).Trim());
            if (firstDate == null) return periods;

            // Parse end date
            int spaceAfterMid = text.IndexOf(" ", mid + 1);
            int commaAfterMid = text.IndexOf(",", mid + 1);
            if (spaceAfterMid == -1 || commaAfterMid == -1) return periods;

            var secondDate = ParseDateOnly(text.Substring(spaceAfterMid + 1, commaAfterMid - (spaceAfterMid + 1)).Trim());
            if (secondDate == null) return periods;

            // If "each night" with "and", create separate periods for each night
            if (isEachNight && text.IndexOf(" and ", endIdx) == mid)
            {
                periods.Add(new DisruptionPeriod
                {
                    StartDateTime = firstDate.Value.ToDateTime(startTime.Time ?? TimeOnly.MinValue),
                    EndDateTime = endTime.IsLastService
                        ? firstDate.Value.ToDateTime(new TimeOnly(23, 59, 59))
                        : firstDate.Value.ToDateTime(endTime.Time ?? TimeOnly.MinValue),
                    IsLastService = endTime.IsLastService
                });

                periods.Add(new DisruptionPeriod
                {
                    StartDateTime = secondDate.Value.ToDateTime(startTime.Time ?? TimeOnly.MinValue),
                    EndDateTime = endTime.IsLastService
                        ? secondDate.Value.ToDateTime(new TimeOnly(23, 59, 59))
                        : secondDate.Value.ToDateTime(endTime.Time ?? TimeOnly.MinValue),
                    IsLastService = endTime.IsLastService
                });
            }
            // If "each night" with "to", create period for each night in range
            else if (isEachNight && text.IndexOf(" to ", endIdx) == mid)
            {
                var currentDate = firstDate.Value;
                while (currentDate <= secondDate.Value)
                {
                    periods.Add(new DisruptionPeriod
                    {
                        StartDateTime = currentDate.ToDateTime(startTime.Time ?? TimeOnly.MinValue),
                        EndDateTime = endTime.IsLastService
                            ? currentDate.ToDateTime(new TimeOnly(23, 59, 59))
                            : currentDate.ToDateTime(endTime.Time ?? TimeOnly.MinValue),
                        IsLastService = endTime.IsLastService
                    });
                    currentDate = currentDate.AddDays(1);
                }
            }
            else
            {
                // Single continuous period
                startTime.Date = firstDate;
                endTime.Date = secondDate;

                periods.Add(new DisruptionPeriod
                {
                    StartDateTime = startTime.ToDateTime(),
                    EndDateTime = endTime.ToDateTime(),
                    IsLastService = endTime.IsLastService
                });
            }

            return periods;
        }

        // Parse tram disruptions: "No route X trams run between [location A] and [location B]"
        private static DisruptionEvent? ParseTramDisruption(string text)
        {
            if (!text.Contains("tram", StringComparison.OrdinalIgnoreCase))
                return null;

            // Pattern: "No route X trams run between..."
            var noRouteMatch = Regex.Match(text,
                @"No route (\d+) trams run between (.+?) and (.+?)[\.,]",
                RegexOptions.IgnoreCase);

            if (noRouteMatch.Success)
            {
                var routeNumber = noRouteMatch.Groups[1].Value;
                var locationA = noRouteMatch.Groups[2].Value.Trim();
                var locationB = noRouteMatch.Groups[3].Value.Trim();

                return new DisruptionEvent
                {
                    EventType = "service_suspended",
                    RouteType = 1, // Tram
                    RouteNumber = routeNumber,
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = locationA,
                        EndLocation = locationB,
                        Type = "segment"
                    },
                    Periods = new List<DisruptionPeriod>() // No specific time period - ongoing
                };
            }

            // Pattern: "Route X trams [action] between..."
            var routeMatch = Regex.Match(text,
                @"Route (\d+) trams .+? between (.+?) and (.+?)[\.,]",
                RegexOptions.IgnoreCase);

            if (routeMatch.Success)
            {
                var routeNumber = routeMatch.Groups[1].Value;
                var locationA = routeMatch.Groups[2].Value.Trim();
                var locationB = routeMatch.Groups[3].Value.Trim();

                return new DisruptionEvent
                {
                    EventType = "service_disrupted",
                    RouteType = 1, // Tram
                    RouteNumber = routeNumber,
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = locationA,
                        EndLocation = locationB,
                        Type = "segment"
                    },
                    Periods = new List<DisruptionPeriod>()
                };
            }

            return null;
        }

        // Parse V/Line disruptions: "Coaches replace trains..." or coach delays
        private static DisruptionEvent? ParseVLineDisruption(string text)
        {
            ReadOnlySpan<char> span = text.AsSpan();

            // Pattern: "Coaches replace trains between X and Y..."
            if (text.StartsWith("Coaches replace trains", StringComparison.OrdinalIgnoreCase))
            {
                int betweenIdx = text.IndexOf("between ");
                if (betweenIdx == -1) return null;
                betweenIdx += "between ".Length;

                int andIdx = text.IndexOf(" and ", betweenIdx);
                if (andIdx == -1) return null;

                var locationA = span[betweenIdx..andIdx].ToString().Trim();

                // Extract locationB (up to "from" or punctuation)
                int fromIdx = text.IndexOf(" from ", andIdx);
                int periodIdx = text.IndexOfAny(new[] { '.', ',' }, andIdx);
                int endIdx = fromIdx != -1 ? fromIdx : (periodIdx != -1 ? periodIdx : text.Length);

                var locationB = text.Substring(andIdx + " and ".Length, endIdx - (andIdx + " and ".Length)).Trim();

                // Parse time period using unified function
                List<DisruptionPeriod> periods = new List<DisruptionPeriod>();
                if (fromIdx != -1)
                {
                    periods = ParseTimePeriod(text, fromIdx);
                }

                return new DisruptionEvent
                {
                    EventType = "replacement_service",
                    RouteType = 3, // V/Line
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = locationA,
                        EndLocation = locationB,
                        Type = "segment"
                    },
                    Replacement = new ReplacementService
                    {
                        Mode = "coach",
                        RouteType = 2 // Bus/Coach
                    },
                    Periods = periods
                };
            }

            // Pattern: "The [time] [origin] to [destination] scheduled coach is delayed [X] minutes"
            // or "... [origin] to [destination] scheduled coach is delayed by [X] minutes"
            var coachDelayMatch = Regex.Match(text,
                @"(?:The\s+)?(?:[\d:\.apm\s]+)?\s*(.+?)\s+to\s+(.+?)\s+scheduled coach is delayed\s+(?:by\s+)?(\d+)\s+minutes",
                RegexOptions.IgnoreCase);

            if (coachDelayMatch.Success)
            {
                var origin = coachDelayMatch.Groups[1].Value.Trim();
                var destination = coachDelayMatch.Groups[2].Value.Trim();
                var delayMinutes = coachDelayMatch.Groups[3].Value;

                return new DisruptionEvent
                {
                    EventType = "delay",
                    RouteType = 3, // V/Line
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = origin,
                        EndLocation = destination,
                        Type = "route"
                    },
                    DelayMinutes = int.TryParse(delayMinutes, out int delay) ? delay : null,
                    Periods = new List<DisruptionPeriod>()
                };
            }

            return null;
        }


        // Parse station facility disruptions: "Temporary closure of North side entrance to Bell station"
        // Or "Southern Cross Station: escalator upgrade works"
        private static DisruptionEvent? ParseStationDisruption(string text)
        {
            if (!text.Contains("station", StringComparison.OrdinalIgnoreCase))
                return null;

            // Pattern 1: "... [facility] at/to [Station Name] station"
            // Examples: "Temporary closure of North side entrance to Bell station"
            //           "Lift fault at Flinders Street station"
            var facilityPattern = Regex.Match(text,
                @"(entrance|lift|escalator|toilet|gate|platform|access).*?(?:at|to)\s+(.+?)\s+station",
                RegexOptions.IgnoreCase);

            if (facilityPattern.Success)
            {
                var facility = facilityPattern.Groups[1].Value.ToLower();
                var stationName = facilityPattern.Groups[2].Value.Trim();

                return new DisruptionEvent
                {
                    EventType = "station_facility",
                    RouteType = 0, // Default to Train, can be overridden
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = stationName,
                        Type = "station",
                        Facility = facility
                    },
                    Periods = new List<DisruptionPeriod>()
                };
            }

            // Pattern 2: "[Station Name] Station: [facility] [issue]"
            // Examples: "Southern Cross Station: escalator upgrade works"
            //           "Parliament Station: lift out of service"
            var stationFirstPattern = Regex.Match(text,
                @"^(.+?)\s+Station:\s+(entrance|lift|escalator|toilet|gate|platform|access)\s+",
                RegexOptions.IgnoreCase);

            if (stationFirstPattern.Success)
            {
                var stationName = stationFirstPattern.Groups[1].Value.Trim();
                var facility = stationFirstPattern.Groups[2].Value.ToLower();

                return new DisruptionEvent
                {
                    EventType = "station_facility",
                    RouteType = 0, // Default to Train
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = stationName,
                        Type = "station",
                        Facility = facility
                    },
                    Periods = new List<DisruptionPeriod>()
                };
            }

            // Pattern 3: "Temporary closure of [facility] ... [Station Name] station"
            // Examples: "Temporary closure of North side entrance to Bell station due to a fault"
            var closurePattern = Regex.Match(text,
                @"(?:Temporary\s+)?(?:closure|closed).*?(entrance|lift|escalator|toilet|gate|platform|access).*?(?:to|at)\s+(.+?)\s+station",
                RegexOptions.IgnoreCase);

            if (closurePattern.Success)
            {
                var facility = closurePattern.Groups[1].Value.ToLower();
                var stationName = closurePattern.Groups[2].Value.Trim();

                return new DisruptionEvent
                {
                    EventType = "station_facility",
                    RouteType = 0, // Default to Train
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = stationName,
                        Type = "station",
                        Facility = facility
                    },
                    Periods = new List<DisruptionPeriod>()
                };
            }

            return null;
        }


        // SAMPLE 1: "Buses replace trains between Newport and Werribee from 10.30pm to last service each night, Monday 22 December and Tuesday 23 December, while we test the new X'Trapolis 2.0 trains."
        // SAMPLE 2: "Buses replace trains between Newport and Werribee from 10.30pm Saturday 20 December to 6am Sunday 21 December, while we test the new X'Trapolis 2.0 trains.
        // SAMPLE 3: "Buses replace trains between South Yarra and Moorabbin from 8:30pm to last service each night, Monday 8 December to Wednesday 10 December, due to maintenance works.
        // SAMPLE 4 (Tram): "No route 82 trams run between Stop 37 Union Road and Moonee Ponds."
        // SAMPLE 5 (V/Line): "Coaches replace trains between Geelong and Melbourne from 9:00am to 5:00pm Saturday 25 December."
        // SAMPLE 6 (Station): "Temporary closure of North side entrance to Bell station due to a fault"
        public static DisruptionEvent? ParseDisruptionDescription(string text)
        {
            ReadOnlySpan<char> span = text.AsSpan();

            if (string.IsNullOrEmpty(text))
            {
                return null;
            }

            // Check for station facility disruptions first
            var stationEvent = ParseStationDisruption(text);
            if (stationEvent != null) return stationEvent;

            // Check for tram disruption pattern
            var tramEvent = ParseTramDisruption(text);
            if (tramEvent != null) return tramEvent;

            // Check for V/Line coach replacement
            var vlineEvent = ParseVLineDisruption(text);
            if (vlineEvent != null) return vlineEvent;

            int spaceIndex = span.IndexOf(' ');
            if (spaceIndex == -1) return null;

            string firstWord = span[..spaceIndex].ToString();

            if (firstWord.Trim().Equals("buses", StringComparison.CurrentCultureIgnoreCase))
            {
                // Find all positions sequentially
                int betweenIdx = text.IndexOf("between ");
                if (betweenIdx == -1) return null;
                betweenIdx += "between ".Length;

                int andIdx = text.IndexOf(" and ", betweenIdx);
                if (andIdx == -1) return null;

                int fromIdx = text.IndexOf(" from ", andIdx);
                if (fromIdx == -1) return null;

                // Extract station names
                var stationA = span[betweenIdx..andIdx].ToString().Trim();
                var stationB = span[(andIdx + " and ".Length)..fromIdx].ToString().Trim();

                // Parse time period using unified function
                List<DisruptionPeriod> periods = ParseTimePeriod(text, fromIdx);



                // Build DisruptionEvent
                return new DisruptionEvent
                {
                    EventType = "replacement_service",
                    RouteType = 0, // Train
                    AffectedArea = new DisruptionLocation
                    {
                        StartLocation = stationA,
                        EndLocation = stationB,
                        Type = "segment"
                    },
                    Replacement = new ReplacementService
                    {
                        Mode = "bus",
                        RouteType = 2 // Bus
                    },
                    Periods = periods
                };
            }

            return null;

        }
       

        [GeneratedRegex(@"\.(\d)")]
        private static partial Regex MyRegex();
    }
}