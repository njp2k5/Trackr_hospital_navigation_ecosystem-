import { useWardStaff } from "@/hooks/useHospitalData";
import { getWardDisplayName } from "@/lib/utils";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Stethoscope, UserCheck, UserX, Users } from "lucide-react";
import { cn } from "@/lib/utils";

interface WardStaffModalProps {
  wardId: string | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function WardStaffModal({
  wardId,
  open,
  onOpenChange,
}: WardStaffModalProps) {
  const { data, isLoading } = useWardStaff(wardId || "");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg gradient-teal shadow-teal">
              <Users className="h-5 w-5 text-primary-foreground" />
            </div>
            <div>
              <span className="text-black">{getWardDisplayName(wardId || "")} Staff</span>
              <p className="text-sm font-normal text-muted-foreground mt-0.5">
                Current shift assignments
              </p>
            </div>
          </DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <div className="space-y-4 py-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-12 rounded-lg animate-shimmer" />
            ))}
          </div>
        ) : data ? (
          <div className="space-y-6 py-4">
            {/* Nurses */}
            <div className="flex items-center justify-between rounded-lg border border-border bg-accent/50 p-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                  <Users className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <p className="font-medium text-foreground">Nurses on Duty</p>
                  <p className="text-sm text-muted-foreground">
                    Active shift coverage
                  </p>
                </div>
              </div>
              <span className="text-3xl font-bold text-foreground">
                {data.nurses_on_duty}
              </span>
            </div>

            {/* Doctors on Duty */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <UserCheck className="h-4 w-4 text-success" />
                <h3 className="font-medium text-foreground">Doctors on Duty</h3>
                <span className="text-xs text-muted-foreground">
                  ({data.doctors.on_duty.length})
                </span>
              </div>
              <div className="space-y-2">
                {data.doctors.on_duty.map((doctor, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-3 rounded-lg border border-border bg-card p-3"
                  >
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-success/10">
                      <Stethoscope className="h-4 w-4 text-success" />
                    </div>
                    <div>
                      <p className="font-medium text-foreground">
                        {doctor.name}
                      </p>
                      {doctor.specialty && (
                        <p className="text-xs text-muted-foreground">
                          {doctor.specialty}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Absent Doctors */}
            {data.doctors.absent.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <UserX className="h-4 w-4 text-warning" />
                  <h3 className="font-medium text-foreground">Absent</h3>
                  <span className="text-xs text-muted-foreground">
                    ({data.doctors.absent.length})
                  </span>
                </div>
                <div className="space-y-2">
                  {data.doctors.absent.map((doctor, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between rounded-lg border border-warning/20 bg-warning/5 p-3"
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-warning/10">
                          <UserX className="h-4 w-4 text-warning" />
                        </div>
                        <p className="font-medium text-foreground">
                          {doctor.name}
                        </p>
                      </div>
                      {doctor.substitute && (
                        <div className="text-right">
                          <p className="text-xs text-muted-foreground">
                            Substitute
                          </p>
                          <p className="text-sm font-medium text-foreground">
                            {doctor.substitute}
                          </p>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
