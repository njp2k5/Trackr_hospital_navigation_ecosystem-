import { useMaintenance } from "@/hooks/useHospitalData";
import { MaintenanceItem } from "@/lib/api";
import { cn } from "@/lib/utils";
import { Wrench, Clock, CheckCircle, Loader2 } from "lucide-react";
import { ScrollArea } from "@/components/ui/scroll-area";

const statusConfig = {
  "in progress": {
    icon: Loader2,
    text: "text-warning",
    bg: "bg-warning/10",
    iconClass: "animate-spin",
  },
  completed: {
    icon: CheckCircle,
    text: "text-success",
    bg: "bg-success/10",
    iconClass: "",
  },
  scheduled: {
    icon: Clock,
    text: "text-muted-foreground",
    bg: "bg-muted",
    iconClass: "",
  },
};

function MaintenanceItemCard({ item }: { item: MaintenanceItem }) {
  const config =
    statusConfig[item.status.toLowerCase() as keyof typeof statusConfig] ||
    statusConfig.scheduled;
  const Icon = config.icon;

  return (
    <div className="flex items-center gap-4 rounded-lg border border-border bg-card/50 p-4 transition-all hover:border-primary/20 hover:shadow-sm">
      <div className={cn("rounded-lg p-2.5", config.bg)}>
        <Wrench className={cn("h-4 w-4", config.text)} />
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <p className="font-medium text-foreground capitalize truncate">
            {item.type}
          </p>
          <div
            className={cn(
              "flex items-center gap-1 rounded-full px-2 py-0.5",
              config.bg
            )}
          >
            <Icon className={cn("h-3 w-3", config.text, config.iconClass)} />
            <span className={cn("text-xs font-medium capitalize", config.text)}>
              {item.status}
            </span>
          </div>
        </div>
        <p className="text-sm text-muted-foreground mt-0.5 truncate">
          {item.location}
        </p>
      </div>

      {item.expected_completion && (
        <div className="text-right shrink-0">
          <p className="text-xs text-muted-foreground">Expected</p>
          <p className="text-sm font-medium text-foreground">
            {new Date(item.expected_completion).toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </p>
        </div>
      )}
    </div>
  );
}

export function MaintenancePanel() {
  const { data, isLoading } = useMaintenance();

  const activeCount =
    data?.maintenance.filter(
      (m) => m.status.toLowerCase() === "in progress"
    ).length || 0;

  return (
    <div className="rounded-xl border bg-card shadow-card">
      <div className="flex items-center justify-between border-b border-border p-5">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent">
            <Wrench className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h2 className="font-semibold text-foreground">Maintenance</h2>
            <p className="text-xs text-muted-foreground">Ongoing activities</p>
          </div>
        </div>
        {activeCount > 0 && (
          <span className="rounded-full bg-warning/10 px-2.5 py-1 text-xs font-medium text-warning">
            {activeCount} Active
          </span>
        )}
      </div>

      <ScrollArea className="h-[280px]">
        <div className="space-y-3 p-5">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="h-16 rounded-lg animate-shimmer" />
            ))
          ) : data?.maintenance.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-success/10 mb-3">
                <CheckCircle className="h-6 w-6 text-success" />
              </div>
              <p className="text-sm font-medium text-foreground">
                All Clear
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                No ongoing maintenance
              </p>
            </div>
          ) : (
            data?.maintenance.map((item, index) => (
              <MaintenanceItemCard key={index} item={item} />
            ))
          )}
        </div>
      </ScrollArea>
    </div>
  );
}
