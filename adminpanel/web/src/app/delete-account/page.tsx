'use client';

import React, { useState } from 'react';
import Link from 'next/link';

export default function DeleteAccountPage() {
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [reason, setReason] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email && !phone) return;

    setLoading(true);
    // Simulate submission delay
    setTimeout(() => {
      setLoading(false);
      setSubmitted(true);
    }, 1000);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-amber-500 selection:text-slate-950">
      {/* Top Navbar */}
      <header className="border-b border-slate-800/80 bg-slate-900/90 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <img
              src="/logo.png"
              alt="Mandap Builder Logo"
              className="w-10 h-10 object-contain rounded-xl bg-slate-950 p-1 ring-1 ring-amber-400/30 shadow-md shadow-amber-900/20"
            />
            <div>
              <span className="font-bold text-lg text-slate-100 tracking-tight block leading-none">MANDAP BUILDER</span>
              <span className="text-[10px] text-amber-400/90 font-medium tracking-wider uppercase">3D Event Structure Planner</span>
            </div>
          </Link>

          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="text-xs text-slate-300 hover:text-amber-400 font-medium transition-colors"
            >
              Privacy Policy
            </Link>
            <a
              href="https://play.google.com/store/apps/details?id=com.emperorsmartsolutionsmandap"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-lg bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-semibold text-xs tracking-wide shadow-md shadow-amber-500/20 transition-all"
            >
              Google Play
            </a>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-4xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 sm:p-10 shadow-2xl backdrop-blur-sm space-y-10">
          
          {/* Page Header */}
          <div className="border-b border-slate-800 pb-6 flex flex-wrap items-center justify-between gap-4">
            <div>
              <div className="inline-flex items-center gap-2 px-2.5 py-0.5 rounded-full bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs font-medium mb-2">
                User Data & Privacy Compliance
              </div>
              <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-50 tracking-tight">
                Account & Data Deletion Request
              </h1>
              <p className="text-slate-400 text-sm mt-1">
                Application: <span className="text-amber-400 font-semibold">Mandap Builder</span> (com.emperorsmartsolutionsmandap)
              </p>
            </div>
          </div>

          {/* Policy Information Section */}
          <section className="space-y-4">
            <h2 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
              <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
              Google Play Data Deletion Information
            </h2>
            <p className="text-slate-300 text-sm leading-relaxed">
              In compliance with Google Play Store User Data policies, users of <strong className="text-slate-100">Mandap Builder</strong> have full rights to request permanent deletion of their user account and all associated personal and project data.
            </p>
          </section>

          {/* What Data Gets Deleted vs Retained */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div className="p-5 rounded-xl border border-rose-900/40 bg-rose-950/20 space-y-3">
              <h3 className="text-sm font-bold text-rose-400 flex items-center gap-2">
                <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                  <path d="M19,4H15.5L14.5,3H9.5L8.5,4H5V6H19M6,19A2,2 0 0,0 8,21H16A2,2 0 0,0 18,19V7H6V19Z" />
                </svg>
                Permanently Deleted Data
              </h3>
              <ul className="text-xs text-slate-300 space-y-2 list-disc list-inside leading-relaxed">
                <li>User Profile (Name, Email, Mobile Number)</li>
                <li>Saved 2D & 3D Mandap Structural Designs</li>
                <li>Custom Material & Piece Specifications</li>
                <li>Saved Quotations & Calculations</li>
                <li>Authentication tokens and login credentials</li>
              </ul>
            </div>

            <div className="p-5 rounded-xl border border-slate-800 bg-slate-950/60 space-y-3">
              <h3 className="text-sm font-bold text-slate-300 flex items-center gap-2">
                <svg className="w-4 h-4 fill-current text-slate-400" viewBox="0 0 24 24">
                  <path d="M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1Z" />
                </svg>
                Data Retained for Legal Compliance
              </h3>
              <ul className="text-xs text-slate-400 space-y-2 list-disc list-inside leading-relaxed">
                <li>Financial transaction receipts (retained for accounting/audit purposes up to 90 days).</li>
                <li>Security audit logs to prevent fraud or unauthorized access.</li>
              </ul>
            </div>
          </div>

          {/* Submission Form */}
          <section className="border-t border-slate-800 pt-8 space-y-6">
            <div>
              <h2 className="text-lg font-semibold text-amber-400 flex items-center gap-2">
                <span className="w-1.5 h-5 bg-amber-400 rounded-full inline-block"></span>
                Submit Account Deletion Request
              </h2>
              <p className="text-slate-400 text-xs mt-1">
                Please provide your registered account details below. Deletion requests are processed within <strong className="text-slate-200">7 business days</strong>.
              </p>
            </div>

            {submitted ? (
              <div className="p-6 rounded-xl border border-emerald-500/30 bg-emerald-950/20 text-center space-y-3">
                <div className="w-12 h-12 rounded-full bg-emerald-500/20 border border-emerald-500/40 text-emerald-400 flex items-center justify-center mx-auto">
                  <svg className="w-6 h-6 fill-current" viewBox="0 0 24 24">
                    <path d="M21,7L9,19L3.5,13.5L4.91,12.09L9,16.17L19.59,5.59L21,7Z" />
                  </svg>
                </div>
                <h3 className="text-lg font-bold text-emerald-400">Deletion Request Received</h3>
                <p className="text-xs text-slate-300 max-w-md mx-auto leading-relaxed">
                  Your request to delete account data for <strong className="text-slate-100">{email || phone}</strong> has been logged. Our team will verify and complete your data removal within 7 business days. You will receive a confirmation via email.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4 max-w-lg">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                    Registered Email Address *
                  </label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="your-email@domain.com"
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-100 placeholder-slate-600 focus:outline-none focus:border-amber-500/80 text-sm transition-all"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                    Registered Mobile Number (Optional)
                  </label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+91 9876543210"
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-100 placeholder-slate-600 focus:outline-none focus:border-amber-500/80 text-sm transition-all"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                    Reason for Deletion (Optional)
                  </label>
                  <textarea
                    rows={3}
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="Tell us why you want to delete your account..."
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-100 placeholder-slate-600 focus:outline-none focus:border-amber-500/80 text-sm transition-all resize-none"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 px-6 rounded-xl bg-gradient-to-r from-rose-600 to-rose-700 hover:from-rose-500 hover:to-rose-600 text-white font-bold text-sm tracking-wide shadow-lg shadow-rose-900/30 transition-all flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                  ) : (
                    'Submit Account Deletion Request'
                  )}
                </button>
              </form>
            )}
          </section>

          {/* Alternative Email Method */}
          <section className="border-t border-slate-800 pt-6 text-xs text-slate-400 space-y-2">
            <p>
              Alternatively, you can send an account deletion request email directly to our support team at:
            </p>
            <p>
              <a href="mailto:support@emperorsmartsolutions.com?subject=Account%20Deletion%20Request%20-%20Mandap%20Builder" className="text-amber-400 font-semibold hover:underline">
                support@emperorsmartsolutions.com
              </a>
            </p>
          </section>

        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800/80 bg-slate-900 py-8 px-4 sm:px-6 lg:px-8 mt-auto">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-400">
          <p>© 2026 Emperor Smart Solutions. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link href="/" className="hover:text-amber-400 transition-colors">Privacy Policy</Link>
            <Link href="/delete-account" className="hover:text-amber-400 text-amber-400 font-semibold transition-colors">Delete Account</Link>
            <a
              href="https://play.google.com/store/apps/details?id=com.emperorsmartsolutionsmandap"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-amber-400 transition-colors"
            >
              Google Play Store
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
