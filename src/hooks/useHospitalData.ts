import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";

export function useWardsStatus() {
  return useQuery({
    queryKey: ["wards-status"],
    queryFn: api.getWardsStatus,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
}

export function useWardStaff(wardId: string) {
  return useQuery({
    queryKey: ["ward-staff", wardId],
    queryFn: () => api.getWardStaff(wardId),
    enabled: !!wardId,
  });
}

export function useMaintenance() {
  return useQuery({
    queryKey: ["maintenance"],
    queryFn: api.getMaintenance,
    refetchInterval: 60000, // Refresh every minute
  });
}

export function useAlerts() {
  return useQuery({
    queryKey: ["alerts"],
    queryFn: api.getAlerts,
    refetchInterval: 15000, // Refresh every 15 seconds
  });
}

export function useRealtimeSummary() {
  return useQuery({
    queryKey: ["realtime-summary"],
    queryFn: api.getRealtimeSummary,
    refetchInterval: 10000, // Refresh every 10 seconds
  });
}

export function useHealthStatus() {
  return useQuery({
    queryKey: ["health"],
    queryFn: api.getHealth,
    refetchInterval: 30000,
  });
}
