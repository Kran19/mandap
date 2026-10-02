import Link from 'next/link';

export const metadata = {
  title: 'Privacy Policy | Mandap Builder - 3D Event Planner',
  description: 'Official Privacy Policy and Play Store details for Mandap Builder (com.emperorsmartsolutionsmandap) by Emperor Smart Solutions.',
};

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-amber-500 selection:text-slate-950">
      {/* Top Navbar */}
      <header className="border-b border-slate-800/80 bg-slate-900/90 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 via-rose-600 to-amber-700 flex items-center justify-center shadow-lg shadow-amber-900/20 ring-1 ring-amber-400/30">
              <span className="font-black text-xl text-white tracking-tighter">M</span>
            </div>
            <div>
              <span className="font-bold text-lg text-slate-100 tracking-tight block leading-none">MANDAP BUILDER</span>
              <span className="text-[10px] text-amber-400/90 font-medium tracking-wider uppercase">3D Event Structure Planner</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <a
              href="https://play.google.com/store/apps/details?id=com.emperorsmartsolutionsmandap"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-semibold text-xs tracking-wide shadow-md shadow-amber-500/20 transition-all transform hover:-translate-y-0.5"
            >
              <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.5,12.92 20.16,13.19L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" />
              </svg>
              Get on Google Play
            </a>
            <Link
              href="/login"
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-slate-700 bg-slate-800/80 hover:bg-slate-800 text-slate-200 text-xs font-semibold tracking-wide transition-all"
            >
              Admin Portal
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Banner */}
      <section className="relative overflow-hidden bg-gradient-to-b from-slate-900 via-slate-900 to-slate-950 border-b border-slate-800/60 py-16 px-4 sm:px-6 lg:px-8">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(245,158,11,0.08),transparent_50%)]"></div>
        <div className="max-w-4xl mx-auto relative z-10 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs font-medium mb-6">
            <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
            Official Application Privacy Policy & Product Listing
          </div>

          <h1 className="text-3xl sm:text-5xl font-extrabold text-slate-50 tracking-tight leading-tight mb-4">
            Mandap Builder <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-400 to-rose-400">3D Event Planner</span>
          </h1>

          <p className="text-slate-400 text-base sm:text-lg max-w-2xl mx-auto mb-8 font-normal leading-relaxed">
            Designed for event decor contractors, wedding planners, and truss fabricators to design, visualize, and calculate 2D/3D mandaps, stage structures, pipe poles, and flooring carpet layouts.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-4">
            <a
              href="https://play.google.com/store/apps/details?id=com.emperorsmartsolutionsmandap"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-3 px-6 py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-rose-600 hover:from-amber-400 hover:to-rose-500 text-slate-950 font-bold text-sm tracking-wide shadow-xl shadow-amber-900/30 transition-all transform hover:-translate-y-0.5"
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.5,12.92 20.16,13.19L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" />
              </svg>
              Download on Google Play Store
            </a>

            <div className="inline-flex items-center gap-2 px-4 py-3 rounded-xl border border-slate-800 bg-slate-900/60 text-slate-300 text-xs font-mono">
              <span className="text-slate-500">Package:</span>
              <span className="text-amber-400 font-semibold">com.emperorsmartsolutionsmandap</span>
            </div>
          </div>
        </div>
      </section>

      {/* Main Privacy Policy Content */}
      <main className="flex-1 max-w-4xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 sm:p-10 shadow-2xl backdrop-blur-sm space-y-10">
          {/* Header Metadata */}
          <div className="border-b border-slate-800 pb-6 flex flex-wrap items-center justify-between gap-4">
            <div>
              <h2 className="text-2xl font-bold text-slate-100">Privacy Policy</h2>
              <p className="text-slate-400 text-sm mt-1">Application: Mandap Builder - 3D Event Planner</p>
            </div>
            <div className="text-right">
              <span className="block text-xs text-slate-500">Last Updated</span>
              <span className="text-sm font-semibold text-amber-400">October 2, 2026</span>
            </div>
          </div>

          {/* Section 1: Overview */}
          <section className="space-y-3">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              1. Overview & Scope
            </h3>
            <p className="text-slate-300 text-sm leading-relaxed">
              This Privacy Policy explains how <strong className="text-slate-100">Emperor Smart Solutions</strong> (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;) collects, uses, discloses, and protects your information when you use our mobile application <strong className="text-slate-100">Mandap Builder - 3D Event Planner</strong> (Package ID: <code className="text-amber-300 bg-slate-950 px-1.5 py-0.5 rounded border border-slate-800">com.emperorsmartsolutionsmandap</code>).
            </p>
            <p className="text-slate-300 text-sm leading-relaxed">
              By installing or using our application, you agree to the collection and use of information in accordance with this policy.
            </p>
          </section>

          {/* Section 2: Information We Collect */}
          <section className="space-y-3">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              2. Information We Collect
            </h3>
            <div className="grid sm:grid-cols-2 gap-4 mt-2">
              <div className="p-4 rounded-xl border border-slate-800 bg-slate-950/50 space-y-2">
                <h4 className="font-semibold text-sm text-slate-200">A. Personal Account Data</h4>
                <p className="text-xs text-slate-400 leading-relaxed">
                  When you register or log into the Mandap Builder app, we may request basic identity information such as your name, mobile phone number, and account password for authentication purposes.
                </p>
              </div>
              <div className="p-4 rounded-xl border border-slate-800 bg-slate-950/50 space-y-2">
                <h4 className="font-semibold text-sm text-slate-200">B. Project & Design Data</h4>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Structural measurements, mandap plot sizes, truss configurations, pole placements, stage dimensions, and flooring estimates created within the editor to allow cloud backup and project retrieval.
                </p>
              </div>
              <div className="p-4 rounded-xl border border-slate-800 bg-slate-950/50 space-y-2">
                <h4 className="font-semibold text-sm text-slate-200">C. Device & Usage Information</h4>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Standard technical diagnostics including operating system version, device model, app crash diagnostics, and performance logs to optimize 3D rendering.
                </p>
              </div>
              <div className="p-4 rounded-xl border border-slate-800 bg-slate-950/50 space-y-2">
                <h4 className="font-semibold text-sm text-slate-200">D. Storage & Permissions</h4>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Optional local storage permissions to allow saving PDF bills of materials (BOM), project exports, or structural screenshot snapshots directly to your device storage.
                </p>
              </div>
            </div>
          </section>

          {/* Section 3: How We Use Your Information */}
          <section className="space-y-3">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              3. How We Use Your Information
            </h3>
            <ul className="list-disc list-inside space-y-2 text-sm text-slate-300 leading-relaxed">
              <li>To provide and maintain app features including 2D & 3D mandap rendering and truss piece calculation algorithms.</li>
              <li>To save, sync, and retrieve your event structural projects across your authorized devices.</li>
              <li>To process user authentication, login requests, and secure access control.</li>
              <li>To provide customer support and troubleshoot technical or calculation issues.</li>
              <li>To improve application reliability, performance, and UI responsiveness.</li>
            </ul>
          </section>

          {/* Section 4: Data Sharing & Protection */}
          <section className="space-y-3">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              4. Data Sharing & Security
            </h3>
            <p className="text-slate-300 text-sm leading-relaxed">
              <strong className="text-slate-100">We do not sell, rent, or trade your personal data to third parties.</strong> All API communications between the application and our servers are encrypted using standard Industry HTTPS / TLS protocols.
            </p>
          </section>

          {/* Section 5: Data Retention & Account Deletion */}
          <section className="space-y-3">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              5. Your Rights & Data Deletion
            </h3>
            <p className="text-slate-300 text-sm leading-relaxed">
              You have the right to access, edit, or delete your account information and stored projects at any time. If you wish to permanently delete your user account and all associated project data, you may submit a request by contacting us at <a href="mailto:support@emperorsmartsolutions.com" className="text-amber-400 hover:underline">support@emperorsmartsolutions.com</a>.
            </p>
          </section>

          {/* Section 6: Children's Privacy */}
          <section className="space-y-3">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              6. Children&apos;s Privacy
            </h3>
            <p className="text-slate-300 text-sm leading-relaxed">
              Our application is designed for event contractors and professionals. Mandap Builder does not knowingly collect personal identifiable information from children under the age of 13.
            </p>
          </section>

          {/* Section 7: Contact Us */}
          <section className="border-t border-slate-800 pt-6 space-y-4">
            <h3 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              7. Developer Contact Information
            </h3>
            <p className="text-slate-300 text-sm leading-relaxed">
              If you have any questions or privacy concerns regarding Mandap Builder, please reach out to us:
            </p>
            <div className="p-4 rounded-xl border border-slate-800 bg-slate-950/80 space-y-2 text-xs sm:text-sm">
              <div className="flex items-center gap-2">
                <span className="text-slate-400 w-24">Developer:</span>
                <span className="font-semibold text-slate-100">Emperor Smart Solutions</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-slate-400 w-24">App Package:</span>
                <span className="font-mono text-amber-400">com.emperorsmartsolutionsmandap</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-slate-400 w-24">Email Contact:</span>
                <a href="mailto:support@emperorsmartsolutions.com" className="text-amber-400 font-semibold hover:underline">
                  support@emperorsmartsolutions.com
                </a>
              </div>
            </div>
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800/80 bg-slate-900 py-8 px-4 sm:px-6 lg:px-8 mt-auto">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-400">
          <p>© 2026 Emperor Smart Solutions. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link href="/" className="hover:text-amber-400 transition-colors">Privacy Policy</Link>
            <a
              href="https://play.google.com/store/apps/details?id=com.emperorsmartsolutionsmandap"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-amber-400 transition-colors"
            >
              Google Play Store
            </a>
            <Link href="/login" className="hover:text-amber-400 transition-colors">Admin Login</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
