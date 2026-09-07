import { Badge } from "./badge";

export function StatusBadge({ status }: { status: string }) {
  let variant: "default" | "secondary" | "destructive" | "outline" | "success" | "warning" = "default";
  
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      variant = 'success';
      break;
    case 'SUSPENDED':
      variant = 'warning';
      break;
    case 'ARCHIVED':
    case 'INACTIVE':
      variant = 'secondary';
      break;
    case 'DELETED':
      variant = 'destructive';
      break;
  }

  return <Badge variant={variant}>{status}</Badge>;
}
