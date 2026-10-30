"use client";

import { useEffect, useState } from "react";

import styles from "./service-worker-manager.module.css";

export function ServiceWorkerManager() {
  const [isOffline, setIsOffline] = useState(false);
  const [waitingWorker, setWaitingWorker] = useState<ServiceWorker | null>(
    null,
  );
  const [isApplyingUpdate, setIsApplyingUpdate] = useState(false);

  useEffect(() => {
    const updateConnectionState = () => setIsOffline(!navigator.onLine);

    updateConnectionState();
    window.addEventListener("online", updateConnectionState);
    window.addEventListener("offline", updateConnectionState);

    return () => {
      window.removeEventListener("online", updateConnectionState);
      window.removeEventListener("offline", updateConnectionState);
    };
  }, []);

  useEffect(() => {
    if (
      process.env.NODE_ENV !== "production" ||
      !("serviceWorker" in navigator)
    ) {
      return;
    }

    let disposed = false;
    let registration: ServiceWorkerRegistration | undefined;
    let installingWorker: ServiceWorker | null = null;
    let hasActivatedWorker = navigator.serviceWorker.controller !== null;

    const showWaitingWorker = () => {
      if (
        !disposed &&
        registration?.waiting &&
        navigator.serviceWorker.controller
      ) {
        setWaitingWorker(registration.waiting);
      }
    };

    const handleInstallingStateChange = () => {
      if (installingWorker?.state === "installed") {
        showWaitingWorker();
      }
    };

    const handleUpdateFound = () => {
      installingWorker?.removeEventListener(
        "statechange",
        handleInstallingStateChange,
      );
      installingWorker = registration?.installing ?? null;
      installingWorker?.addEventListener(
        "statechange",
        handleInstallingStateChange,
      );
    };

    const handleControllerChange = () => {
      if (hasActivatedWorker) {
        window.location.reload();
        return;
      }

      hasActivatedWorker = true;
    };

    navigator.serviceWorker.addEventListener(
      "controllerchange",
      handleControllerChange,
    );

    void navigator.serviceWorker
      .register("/sw.js", { scope: "/" })
      .then((createdRegistration) => {
        if (disposed) {
          return;
        }

        registration = createdRegistration;
        registration.addEventListener("updatefound", handleUpdateFound);
        showWaitingWorker();
      })
      .catch(() => {
        // PWA podpora je progresivní; web zůstává použitelný i bez registrace.
      });

    return () => {
      disposed = true;
      registration?.removeEventListener("updatefound", handleUpdateFound);
      installingWorker?.removeEventListener(
        "statechange",
        handleInstallingStateChange,
      );
      navigator.serviceWorker.removeEventListener(
        "controllerchange",
        handleControllerChange,
      );
    };
  }, []);

  const applyUpdate = () => {
    if (!waitingWorker) {
      return;
    }

    setIsApplyingUpdate(true);
    waitingWorker.postMessage({ type: "SKIP_WAITING" });
  };

  if (!isOffline && !waitingWorker) {
    return null;
  }

  return (
    <aside className={styles.notices} aria-live="polite">
      {isOffline ? (
        <p className={styles.offlineNotice} role="status">
          Jste offline. Dostupný obsah zůstává k dispozici.
        </p>
      ) : null}

      {waitingWorker ? (
        <div className={styles.updateNotice} role="status">
          <p>Je připravená nová verze aplikace.</p>
          <button
            type="button"
            onClick={applyUpdate}
            disabled={isApplyingUpdate}
          >
            {isApplyingUpdate ? "Aktualizuji…" : "Aktualizovat"}
          </button>
        </div>
      ) : null}
    </aside>
  );
}
