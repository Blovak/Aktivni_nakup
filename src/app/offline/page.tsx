import Link from "next/link";

import styles from "./offline.module.css";

export default function OfflinePage() {
  return (
    <main className={styles.page}>
      <section className={styles.card} aria-labelledby="offline-title">
        <p className={styles.eyebrow}>Aktivní nákup</p>
        <h1 id="offline-title">Teď jste offline</h1>
        <p>
          Připojení k internetu není dostupné. Dříve načtený shell aplikace
          funguje dál; synchronizaci dat doplníme v navazujícím kroku.
        </p>
        <Link href="/">Zkusit znovu</Link>
      </section>
    </main>
  );
}
