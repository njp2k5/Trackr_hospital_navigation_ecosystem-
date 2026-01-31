import { useRealtimeSummary, useWardsStatus } from "@/hooks/useHospitalData";
import { StatCard } from "./StatCard";
import { AlertCircle, Bed, Wrench, Building2 } from "lucide-react";

export function SummaryCards() {
  const { data: summary, isLoading: summaryLoading } = useRealtimeSummary();
  const { data: wards, isLoading: wardsLoading } = useWardsStatus();

  const totalBeds = wards?.wards.reduce((acc, w) => acc + w.total_beds, 0) || 0;
  const occupiedBeds =
    wards?.wards.reduce((acc, w) => acc + w.occupied_beds, 0) || 0;
  const availableBeds = totalBeds - occupiedBeds;

  const isLoading = summaryLoading || wardsLoading;

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Active Alerts"
        value={isLoading ? "—" : summary?.total_active_alerts || 0}
        subtitle="Requiring attention"
        icon={AlertCircle}
        variant={
          (summary?.total_active_alerts || 0) > 0 ? "critical" : "default"
        }
        delay={0}
      />
      <StatCard
        title="Available Beds"
        value={isLoading ? "—" : availableBeds}
        subtitle={`of ${totalBeds} total beds`}
        icon={Bed}
        variant="primary"
        delay={100}
      />
      <StatCard
        title="Wards Over Capacity"
        value={isLoading ? "—" : summary?.wards_over_capacity.length || 0}
        subtitle={
          summary?.wards_over_capacity.length
            ? summary.wards_over_capacity.join(", ")
            : "All wards normal"
        }
        icon={Building2}
        variant={
          (summary?.wards_over_capacity.length || 0) > 0 ? "warning" : "default"
        }
        delay={200}
      />
      <StatCard
        title="Maintenance"
        value={isLoading ? "—" : summary?.maintenance_count || 0}
        subtitle="Ongoing activities"
        icon={Wrench}
        variant="default"
        delay={300}
      />
    </div>
  );
}
