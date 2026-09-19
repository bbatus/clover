// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import BulkActionsBar from "@/components/BulkActionsBar";
import { ROLES } from "@/access/roleConstants";

const mockAuth = vi.fn();
const mockSelection = vi.fn();
const toggleAll = vi.fn();
const refresh = vi.fn();

let pathname = "/admin/collections/campaigns";
vi.mock("next/navigation", () => ({
  useRouter: () => ({ refresh }),
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => pathname,
}));

vi.mock("@payloadcms/ui", () => ({
  useAuth: () => mockAuth(),
  useSelection: () => mockSelection(),
  useConfig: () => ({ config: { routes: { admin: "/admin" } }, getEntityConfig: () => ({ admin: { useAsTitle: "title" } }) }),
  useRouteCache: () => ({ clearRouteCache: vi.fn() }),
  useTranslation: () => ({ i18n: { language: "tr" } }),
  Button: ({ children, onClick, disabled }: { children: ReactNode; onClick?: () => void; disabled?: boolean }) => (
    <button type="button" onClick={onClick} disabled={disabled}>
      {children}
    </button>
  ),
}));

function auth(role: string, perms: { update?: boolean; delete?: boolean } = { update: true }) {
  mockAuth.mockReturnValue({ user: { id: 1, role }, permissions: { collections: { campaigns: perms, "blog-posts": perms } } });
}

function selected(ids: (string | number)[]) {
  mockSelection.mockReturnValue({
    count: ids.length,
    selectedIDs: ids,
    selectAll: ids.length ? "some" : "none",
    getQueryParams: () => "",
    toggleAll,
    totalDocs: 20,
  });
}

let fetchMock: ReturnType<typeof vi.fn>;
beforeEach(() => {
  fetchMock = vi.fn(async (url: string) => {
    if (url.startsWith("/api/users")) return { ok: true, json: async () => ({ totalDocs: 0 }) };
    return {
      ok: true,
      json: async () => ({
        action: "publish",
        collection: "campaigns",
        results: [
          { id: "1", title: "Yaz Kampanyası", status: "ok", message: "Tamamlandı." },
          { id: "2", title: "Ekim Kampanyası", status: "skipped", message: "01.10.2026 00:00 (İstanbul) için planlanmış." },
          { id: "3", title: "Eksik Kampanya", status: "failed", message: "Lütfen geçersiz alanları düzeltin: Görsel" },
        ],
        counts: { ok: 1, skipped: 1, failed: 1 },
      }),
    };
  });
  vi.stubGlobal("fetch", fetchMock);
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.clearAllMocks();
});

describe("BulkActionsBar", () => {
  it("renders nothing while no row is selected", () => {
    auth(ROLES.NEW_VERTICAL_MAKER, { update: true, delete: true });
    selected([]);
    const { container } = render(<BulkActionsBar collection="campaigns" />);
    expect(container).toBeEmptyDOMElement();
  });

  it("never shows a Growth Maker a publish or unpublish button", async () => {
    auth(ROLES.GROWTH_MAKER, { update: true, delete: true });
    selected([1, 2]);
    render(<BulkActionsBar collection="campaigns" />);
    expect(await screen.findByText("2 kayıt seçildi")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Yayından kaldırma talebi oluştur" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Seçili taslakları çöp kutusuna taşı" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Seçilenleri yayınla" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Seçilenleri yayından kaldır" })).not.toBeInTheDocument();
  });

  it("stays out of the Çöp (trash) list, which has its own restore controls", () => {
    auth(ROLES.NEW_VERTICAL_MAKER, { update: true, delete: true });
    selected([1]);
    pathname = "/admin/collections/campaigns/trash";
    const { container } = render(<BulkActionsBar collection="campaigns" />);
    pathname = "/admin/collections/campaigns";
    expect(container).toBeEmptyDOMElement();
  });

  it("shows a Growth Maker nothing at all where it has no bulk action", () => {
    auth(ROLES.GROWTH_MAKER, { update: true, delete: false });
    selected([1]);
    const { container } = render(<BulkActionsBar collection="blog-posts" />);
    expect(container).toBeEmptyDOMElement();
  });

  it("gives a Growth Checker publish and unpublish, never delete", () => {
    auth(ROLES.GROWTH_CHECKER, { update: true, delete: false });
    selected([1]);
    render(<BulkActionsBar collection="blog-posts" />);
    expect(screen.getByRole("button", { name: "Seçilenleri yayınla" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Seçilenleri yayından kaldır" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Seçili taslakları çöp kutusuna taşı" })).not.toBeInTheDocument();
  });

  it("confirms, sends the selection to the bulk endpoint and lists every record's outcome", async () => {
    auth(ROLES.NEW_VERTICAL_CHECKER);
    selected([1, 2, 3]);
    render(<BulkActionsBar collection="campaigns" />);

    fireEvent.click(screen.getByRole("button", { name: "Seçilenleri yayınla" }));
    expect(screen.getByRole("dialog")).toHaveTextContent("3 kayıt yayınlansın mı?");
    expect(screen.getByRole("dialog")).toHaveTextContent("planlanmış ve reddedilmiş kampanyalar atlanır");
    // 19.09.2026: publishing needs the explicit "I reviewed each one" statement first.
    expect(screen.getByRole("button", { name: "Evet, devam et" })).toBeDisabled();
    fireEvent.click(screen.getByRole("checkbox", { name: /3 kaydın her birini incelediğimi/ }));
    expect(screen.getByRole("button", { name: "Evet, devam et" })).toBeEnabled();
    fireEvent.click(screen.getByRole("button", { name: "Evet, devam et" }));

    expect(await screen.findByText("Toplu yayınlama sonucu")).toBeInTheDocument();
    const call = fetchMock.mock.calls.find(([url]) => url === "/api/bulk-actions");
    expect(JSON.parse(call![1].body)).toEqual({ collection: "campaigns", action: "publish", ids: ["1", "2", "3"], reviewConfirmed: true });
    expect(screen.getByText("1 başarılı · 1 atlandı · 1 başarısız")).toBeInTheDocument();
    expect(screen.getByText("Lütfen geçersiz alanları düzeltin: Görsel")).toBeInTheDocument();
    expect(screen.getByText("01.10.2026 00:00 (İstanbul) için planlanmış.")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Eksik Kampanya" })).toHaveAttribute("href", "/admin/collections/campaigns/3");
    expect(toggleAll).toHaveBeenCalled();
    expect(refresh).toHaveBeenCalled();
  });

  it("shows the server's own message when the whole request is refused", async () => {
    auth(ROLES.NEW_VERTICAL_CHECKER);
    selected([1]);
    fetchMock.mockImplementation(async (url: string) =>
      url.startsWith("/api/users")
        ? { ok: true, json: async () => ({ totalDocs: 0 }) }
        : { ok: false, status: 400, json: async () => ({ errors: [{ message: "Tek seferde en fazla 100 kayıt işlenebilir." }] }) }
    );
    render(<BulkActionsBar collection="campaigns" />);
    fireEvent.click(screen.getByRole("button", { name: "Seçilenleri yayınla" }));
    fireEvent.click(screen.getByRole("checkbox", { name: /her birini incelediğimi/ }));
    fireEvent.click(screen.getByRole("button", { name: "Evet, devam et" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Tek seferde en fazla 100 kayıt işlenebilir.");
  });
});
