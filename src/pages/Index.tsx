import { DashboardHeader } from "@/components/dashboard/DashboardHeader";
import { SummaryCards } from "@/components/dashboard/SummaryCards";
import { WardsGrid } from "@/components/dashboard/WardsGrid";
import { AlertsPanel } from "@/components/dashboard/AlertsPanel";
import { MaintenancePanel } from "@/components/dashboard/MaintenancePanel";
import { CapacityChart } from "@/components/dashboard/CapacityChart";

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      {/* Decorative gradient background */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute top-0 left-1/4 h-96 w-96 rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute top-1/3 right-1/4 h-64 w-64 rounded-full bg-accent/30 blur-3xl" />
      </div>

      <div className="container py-6 space-y-6">
        <DashboardHeader />
        
        <SummaryCards />

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2">
            <CapacityChart />
          </div>
          <div>
            <AlertsPanel />
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2">
            <WardsGrid />
          </div>
          <div>
            <MaintenancePanel />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Index;
