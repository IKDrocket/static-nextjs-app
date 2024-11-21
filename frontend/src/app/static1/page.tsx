import Link from "next/link";

export default function Static1() {
  return (
    <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <h1 className="text-4xl font-bold">Static1 PAGE</h1>
      <div className="grid grid-cols-2 gap-4">
        <Link
          href="/static1/static1-1"
          className="p-4 text-blue-500 border border-blue-500 rounded-md"
        >
          Static1-1
        </Link>
        <Link
          href="/"
          className="p-4 text-blue-500 border border-blue-500 rounded-md"
        >
          Home
        </Link>
      </div>
    </div>
  );
}
