import config from "../../../../../payload.config";
import { GRAPHQL_POST } from "@payloadcms/next/routes";
import { withApiGuard } from "@/lib/apiGuard";

// 19.09.2026: same shared rate limit + access log as REST (lib/apiGuard.ts).
export const POST = withApiGuard(GRAPHQL_POST(config), config);
