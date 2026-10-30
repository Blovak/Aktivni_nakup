import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import { ServiceWorkerManager } from "./service-worker-manager";

afterEach(() => {
  cleanup();
  Object.defineProperty(navigator, "onLine", {
    configurable: true,
    value: true,
  });
});

describe("ServiceWorkerManager", () => {
  it("oznámí offline stav a po návratu připojení ho skryje", async () => {
    Object.defineProperty(navigator, "onLine", {
      configurable: true,
      value: false,
    });

    render(<ServiceWorkerManager />);

    expect(
      await screen.findByText(
        "Jste offline. Dostupný obsah zůstává k dispozici.",
      ),
    ).toBeTruthy();

    Object.defineProperty(navigator, "onLine", {
      configurable: true,
      value: true,
    });
    fireEvent(window, new Event("online"));

    expect(
      screen.queryByText("Jste offline. Dostupný obsah zůstává k dispozici."),
    ).toBeNull();
  });
});
