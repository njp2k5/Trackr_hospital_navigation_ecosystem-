import { cn } from "@/lib/utils";
import { Ward } from "@/lib/api";
import { Bed, Users } from "lucide-react";

interface WardCardProps {
  ward: Ward;
  onClick?: () => void;
  isSelected?: boolean;
}

export function WardCard({ ward, onClick, isSelected }: WardCardProps) {
  const occupancyRate = Math.round((ward.occupied_beds / ward.total_beds) * 100);
  const isOverCapacity = occupancyRate >= 90;
  const isWarning = occupancyRate >= 75 && occupancyRate < 90;

  return (
    <button
      onClick={onClick}
      className={cn(
        "group relative w-full overflow-hidden rounded-xl border bg-card p-5 text-left transition-all duration-300",
        "hover:shadow-card-hover hover:border-primary/30",
        isSelected && "ring-2 ring-primary border-primary",
        isOverCapacity && "border-destructive/30",
        isWarning && "border-warning/30"
      )}
    >
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="font-semibold text-foreground group-hover:text-primary transition-colors">
            {ward.ward_id}
          </h3>
          <p className="text-xs text-muted-foreground mt-0.5">
            OP #{ward.current_op_number}
          </p>
        </div>
        <div
          className={cn(
            "flex h-10 w-10 items-center justify-center rounded-lg transition-colors",
            isOverCapacity
              ? "bg-destructive/10 text-destructive"
              : isWarning
              ? "bg-warning/10 text-warning"
              : "bg-accent text-primary"
          )}
        >
          <Bed className="h-5 w-5" />
        </div>
      </div>

      <div className="space-y-3">
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Occupancy</span>
          <span
            className={cn(
              "font-semibold",
              isOverCapacity
                ? "text-destructive"
                : isWarning
                ? "text-warning"
                : "text-foreground"
            )}
          >
            {occupancyRate}%
          </span>
        </div>

        <div className="relative h-2 overflow-hidden rounded-full bg-muted">
          <div
            className={cn(
              "absolute inset-y-0 left-0 rounded-full transition-all duration-500",
              isOverCapacity
                ? "bg-destructive"
                : isWarning
                ? "bg-warning"
                : "gradient-teal"
            )}
            style={{ width: `${Math.min(occupancyRate, 100)}%` }}
          />
        </div>

        <div className="flex items-center justify-between pt-2 border-t border-border">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <Users className="h-3.5 w-3.5" />
            <span>{ward.occupied_beds} occupied</span>
          </div>
          <span className="text-xs text-muted-foreground">
            of {ward.total_beds} beds
          </span>
        </div>
      </div>
    </button>
  );
}
