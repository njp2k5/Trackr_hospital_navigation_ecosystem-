import { useWardsStatus } from "@/hooks/useHospitalData";
import { getWardDisplayName } from "@/lib/utils";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import { BarChart3 } from "lucide-react";

export function CapacityChart() {
  const { data, isLoading } = useWardsStatus();

  const chartData =
    data?.wards.map((ward) => ({
      name: getWardDisplayName(ward.ward_id),
      occupancy: Math.round((ward.occupied_beds / ward.total_beds) * 100),
      occupied: ward.occupied_beds,
      total: ward.total_beds,
    })) || [];

  const getBarColor = (value: number) => {
    if (value >= 90) return "hsl(0 84% 60%)";
    if (value >= 75) return "hsl(38 92% 50%)";
    return "hsl(175 84% 40%)";
  };

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="rounded-lg border border-border bg-card p-3 shadow-lg">
          <p className="font-medium text-black">{label}</p>
          <div className="mt-2 space-y-1 text-sm">
            <p className="text-muted-foreground">
              Occupancy:{" "}
              <span className="font-medium text-black">
                {data.occupancy}%
              </span>
            </p>
            <p className="text-muted-foreground">
              Beds:{" "}
              <span className="font-medium text-black">
                {data.occupied}/{data.total}
              </span>
            </p>
          </div>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="rounded-xl border bg-card shadow-card p-5">
      <div className="flex items-center gap-3 mb-6">
        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent">
          <BarChart3 className="h-5 w-5 text-primary" />
        </div>
        <div>
          <h2 className="font-semibold text-foreground">Ward Capacity</h2>
          <p className="text-xs text-muted-foreground">
            Occupancy rates by department
          </p>
        </div>
      </div>

      {isLoading ? (
        <div className="h-[240px] animate-shimmer rounded-lg" />
      ) : (
        <ResponsiveContainer width="100%" height={240}>
          <BarChart data={chartData} barCategoryGap="20%">
            <CartesianGrid
              strokeDasharray="3 3"
              stroke="hsl(180 20% 90%)"
              vertical={false}
            />
            <XAxis
              dataKey="name"
              tick={{ fontSize: 12, fill: "#000000" }}
              tickLine={false}
              axisLine={{ stroke: "hsl(180 20% 90%)" }}
            />
            <YAxis
              tick={{ fontSize: 12, fill: "#000000" }}
              tickLine={false}
              axisLine={false}
              domain={[0, 100]}
              tickFormatter={(value) => `${value}%`}
            />
            <Tooltip content={<CustomTooltip />} cursor={{ fill: "hsl(180 30% 96%)" }} />
            <Bar dataKey="occupancy" radius={[6, 6, 0, 0]} maxBarSize={48}>
              {chartData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={getBarColor(entry.occupancy)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      )}

      <div className="flex items-center justify-center gap-6 mt-4 pt-4 border-t border-border">
        <div className="flex items-center gap-2">
          <div className="h-3 w-3 rounded-full" style={{ background: "hsl(175 84% 40%)" }} />
          <span className="text-xs text-muted-foreground">Normal (&lt;75%)</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="h-3 w-3 rounded-full" style={{ background: "hsl(38 92% 50%)" }} />
          <span className="text-xs text-muted-foreground">Warning (75-90%)</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="h-3 w-3 rounded-full" style={{ background: "hsl(0 84% 60%)" }} />
          <span className="text-xs text-muted-foreground">Critical (&gt;90%)</span>
        </div>
      </div>
    </div>
  );
}
