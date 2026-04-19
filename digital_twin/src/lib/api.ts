const API_BASE = (
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8001"
).replace(/\/$/, "");

export interface Ward {
  ward_id: string;
  current_op_number: number;
  total_beds: number;
  occupied_beds: number;
}

export interface WardStatusResponse {
  wards: Ward[];
}

export interface Doctor {
  name: string;
  specialty?: string;
}

export interface AbsentDoctor {
  name: string;
  substitute?: string;
}

export interface WardStaff {
  ward_id: string;
  doctors: {
    on_duty: Doctor[];
    absent: AbsentDoctor[];
  };
  nurses_on_duty: number;
}

export interface MaintenanceItem {
  type: string;
  location: string;
  status: string;
  expected_completion: string | null;
}

export interface MaintenanceResponse {
  maintenance: MaintenanceItem[];
}

export interface Alert {
  level: "critical" | "warning" | "info";
  message: string;
  timestamp?: string;
}

export interface AlertsResponse {
  alerts: Alert[];
}

export interface RealtimeSummary {
  total_active_alerts: number;
  wards_over_capacity: string[];
  maintenance_count: number;
}

export interface HealthStatus {
  status: string;
  service: string;
}

async function fetchApi<T>(endpoint: string): Promise<T> {
  const response = await fetch(`${API_BASE}${endpoint}`);
  if (!response.ok) {
    throw new Error(`API Error ${response.status}: ${endpoint}`);
  }
  return response.json();
}

export const api = {
  getWardsStatus: () => fetchApi<WardStatusResponse>("/wards/status"),
  getWardStaff: (wardId: string) => fetchApi<WardStaff>(`/wards/${wardId}/staff`),
  getMaintenance: () => fetchApi<MaintenanceResponse>("/maintenance"),
  getAlerts: () => fetchApi<AlertsResponse>("/alerts"),
  getRealtimeSummary: () => fetchApi<RealtimeSummary>("/realtime/summary"),
  getHealth: () => fetchApi<HealthStatus>("/health"),
};
