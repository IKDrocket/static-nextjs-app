import Link from "next/link";

export default function Static2() {
  return (
    <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <h1 className="text-4xl font-bold">
        Static2 PAGE
      </h1>
      <Link href="/" className="p-4 text-blue-500 border border-blue-500 rounded-md">
        Home
      </Link>
    </div>
  );
}