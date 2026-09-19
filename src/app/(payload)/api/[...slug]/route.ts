import config from "../../../../../payload.config";
import "@payloadcms/next/css";
import {
  REST_DELETE,
  REST_GET,
  REST_OPTIONS,
  REST_PATCH,
  REST_POST,
  REST_PUT,
} from "@payloadcms/next/routes";
import { withApiGuard } from "@/lib/apiGuard";
import { withTrashBulk } from "@/lib/trashBulk";

// 19.09.2026: every REST call goes through the shared rate limit + access log (lib/apiGuard.ts).
export const GET = withApiGuard(REST_GET(config), config);
export const POST = withApiGuard(REST_POST(config), config);
// 19.09.2026: the trash screens' bulk restore / permanent delete (lib/trashBulk.ts).
export const DELETE = withApiGuard(withTrashBulk(REST_DELETE(config), config), config);
export const PATCH = withApiGuard(withTrashBulk(REST_PATCH(config), config), config);
export const PUT = withApiGuard(REST_PUT(config), config);
export const OPTIONS = REST_OPTIONS(config);
