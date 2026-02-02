import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

const wardNameMap: Record<string, string> = {
  paediatrics: 'pond1',
  Radeology: 'pond 2',
  'ward c': 'paediatrics',
  'ward d': 'radeology',
};

export function getWardDisplayName(wardId: string): string {
  return wardNameMap[wardId] || wardId;
}
