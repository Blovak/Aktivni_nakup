import styles from "./page.module.css";

const foundations = [
  "Mobilní rozhraní v češtině",
  "Doménová pravidla oddělená od UI",
  "Připraveno pro Supabase a offline outbox",
];

export default function Home() {
  return (
    <main className={styles.page}>
      <section className={styles.card} aria-labelledby="page-title">
        <p className={styles.eyebrow}>Aktivní nákup</p>
        <h1 id="page-title">Základ aplikace je připravený</h1>
        <p className={styles.lead}>
          Sdílený rodinný seznam, který se později seřadí podle pobočky každého
          nakupujícího.
        </p>

        <ul className={styles.checklist} aria-label="Připravené základy">
          {foundations.map((foundation) => (
            <li key={foundation}>{foundation}</li>
          ))}
        </ul>

        <p className={styles.note}>
          Připojení k databázi a přihlášení přidáme v dalších malých krocích.
        </p>
      </section>
    </main>
  );
}
