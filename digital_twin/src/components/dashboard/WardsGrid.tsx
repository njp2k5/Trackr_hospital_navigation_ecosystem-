import { useState } from "react";
import { useWardsStatus } from "@/hooks/useHospitalData";
import { WardCard } from "./WardCard";
import { WardStaffModal } from "./WardStaffModal";
import { Building2 } from "lucide-react";

export function WardsGrid() {
  const { data, isLoading, isError, error } = useWardsStatus();
  const [selectedWard, setSelectedWard] = useState<string | null>(null);

  return (
    <>
      <div className="rounded-xl border bg-card shadow-card">
        <div className="flex items-center justify-between border-b border-border p-5">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg gradient-teal shadow-teal">
              <Building2 className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <h2 className="font-semibold text-foreground">Ward Status</h2>
              <p className="text-xs text-muted-foreground">
                Click to view staff details
              </p>
            </div>
          </div>
          <span className="rounded-full bg-accent px-3 py-1 text-xs font-medium text-accent-foreground">
            {data?.wards.length || 0} Wards
          </span>
        </div>

        <div className="grid gap-4 p-5 sm:grid-cols-2 lg:grid-cols-3">
          {isLoading
            ? Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-40 rounded-xl animate-shimmer" />
              ))
            : isError ? (
                <div className="sm:col-span-2 lg:col-span-3 rounded-xl border border-destructive/20 bg-destructive/5 p-4 text-sm text-muted-foreground">
                  Unable to load ward data. {error instanceof Error ? error.message : "Check the analytics API connection."}
                </div>
              )
            : data?.wards.map((ward) => (
                <WardCard
                  key={ward.ward_id}
                  ward={ward}
                  onClick={() => setSelectedWard(ward.ward_id)}
                  isSelected={selectedWard === ward.ward_id}
                />
              ))}
        </div>
      </div>

      <WardStaffModal
        wardId={selectedWard}
        open={!!selectedWard}
        onOpenChange={(open) => !open && setSelectedWard(null)}
      />
    </>
  );
}
