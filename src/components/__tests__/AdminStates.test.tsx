// @vitest-environment jsdom
import { describe, expect, it, vi, afterEach } from "vitest";
import { act, render, screen, fireEvent, waitFor } from "@testing-library/react";
import { BusyButton, EmptyState, ErrorState, LoadingState, VfSpinner, useBusyAction } from "@/components/AdminStates";

let language = "tr";
vi.mock("@payloadcms/ui", () => ({
  useTranslation: () => ({ i18n: { language } }),
}));

afterEach(() => {
  language = "tr";
  vi.useRealTimers();
});

describe("VfSpinner", () => {
  it("is hidden from screen readers unless labelled", () => {
    const { container, rerender } = render(<VfSpinner />);
    expect(container.querySelector(".vf-spinner")?.getAttribute("aria-hidden")).toBe("true");
    rerender(<VfSpinner label="Görsel yükleniyor" />);
    expect(screen.getByRole("img", { name: "Görsel yükleniyor" })).toBeTruthy();
  });
});

describe("LoadingState", () => {
  it("announces itself politely, in the admin language", () => {
    render(<LoadingState />);
    expect(screen.getByRole("status").textContent).toContain("Yükleniyor…");
    language = "en";
    render(<LoadingState detail="40 records" />);
    expect(screen.getAllByRole("status")[1].textContent).toContain("Loading…");
  });

  it("shows a running seconds counter for long operations", () => {
    vi.useFakeTimers();
    render(<LoadingState label="Taranıyor…" showElapsed />);
    expect(screen.getByRole("status").textContent).not.toContain("sn");
    act(() => {
      vi.advanceTimersByTime(3000);
    });
    expect(screen.getByRole("status").textContent).toContain("3 sn");
  });
});

describe("EmptyState / ErrorState", () => {
  it("empty state is not an alert", () => {
    render(<EmptyState title="Kayıt bulunamadı." hint="İpucu" />);
    expect(screen.queryByRole("alert")).toBeNull();
    expect(screen.getByText("Kayıt bulunamadı.")).toBeTruthy();
  });

  it("error state is an alert with a working retry", async () => {
    let resolve: () => void = () => {};
    const onRetry = vi.fn(() => new Promise<void>((r) => (resolve = r)));
    render(<ErrorState message="Sunucu cevap vermedi" onRetry={onRetry} />);
    expect(screen.getByRole("alert").textContent).toContain("Yüklenemedi");
    const button = screen.getByRole("button", { name: "Tekrar dene" });
    fireEvent.click(button);
    fireEvent.click(button);
    expect(onRetry).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(screen.getByRole("button").textContent).toContain("Deneniyor…"));
    await act(async () => resolve());
    expect(screen.getByRole("button", { name: "Tekrar dene" })).toBeTruthy();
  });

  it("no retry button when nothing can be retried", () => {
    render(<ErrorState message="Yetkiniz yok" />);
    expect(screen.queryByRole("button")).toBeNull();
  });
});

function Harness({ onRun }: { onRun: () => Promise<void> }) {
  const { run, busy, isBusy } = useBusyAction();
  return (
    <>
      <BusyButton busy={busy} onClick={() => run(onRun)} label="Yayınla" busyLabel="İşleniyor…" variant="primary" />
      <button type="button" onClick={() => void run(onRun, "row-1").catch(() => undefined)}>
        row
      </button>
      <span data-testid="row-busy">{String(isBusy("row-1"))}</span>
    </>
  );
}

describe("useBusyAction + BusyButton", () => {
  it("a double click starts the action only once, even within one frame", async () => {
    let resolve: () => void = () => {};
    const onRun = vi.fn(() => new Promise<void>((r) => (resolve = r)));
    render(<Harness onRun={onRun} />);
    const button = screen.getByRole("button", { name: "Yayınla" });
    // Two clicks before React re-renders the disabled state.
    act(() => {
      button.click();
      button.click();
    });
    expect(onRun).toHaveBeenCalledTimes(1);
    const busyButton = screen.getByRole("button", { name: "İşleniyor…" });
    expect(busyButton.hasAttribute("disabled")).toBe(true);
    expect(busyButton.getAttribute("aria-busy")).toBe("true");
    await act(async () => resolve());
    expect(screen.getByRole("button", { name: "Yayınla" }).hasAttribute("disabled")).toBe(false);
  });

  it("per-key locks are independent and released after a failure", async () => {
    const onRun = vi.fn(() => Promise.reject(new Error("x")));
    render(<Harness onRun={onRun} />);
    await act(async () => {
      fireEvent.click(screen.getByRole("button", { name: "row" }));
    });
    await waitFor(() => expect(screen.getByTestId("row-busy").textContent).toBe("false"));
    expect(onRun).toHaveBeenCalledTimes(1);
  });
});
