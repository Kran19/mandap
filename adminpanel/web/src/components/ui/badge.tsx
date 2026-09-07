import * as React from "react"
import { cn } from "@/lib/utils"

export interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "secondary" | "destructive" | "outline" | "success" | "warning";
}

function Badge({ className, variant = "default", ...props }: BadgeProps) {
  const variants = {
    default: "border-transparent bg-gray-900 text-gray-50 hover:bg-gray-900/80",
    secondary: "border-transparent bg-gray-100 text-gray-900 hover:bg-gray-100/80",
    destructive: "border-transparent bg-red-500 text-gray-50 hover:bg-red-500/80",
    outline: "text-gray-950",
    success: "border-transparent bg-green-100 text-green-800 hover:bg-green-100/80",
    warning: "border-transparent bg-yellow-100 text-yellow-800 hover:bg-yellow-100/80",
  }

  return (
    <div
      className={cn(
        "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-gray-950 focus:ring-offset-2",
        variants[variant],
        className
      )}
      {...props}
    />
  )
}

export { Badge }
