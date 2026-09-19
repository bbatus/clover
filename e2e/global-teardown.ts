import { restoreRole } from "./helpers";

/** Whatever happened in the run, the shared test user ends as a New Vertical Maker again. */
export default async function globalTeardown(): Promise<void> {
  await restoreRole();
}
