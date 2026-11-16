import { useState, useEffect, useRef } from 'react'
import { apiFetch, apiUrl } from '../api'
import { useAcademicOptions } from '../hooks/useAcademicOptions'

function AuthPages({ mode = 'login', onNavigate, onLoginSuccess }) {
  const [view, setView] = useState(mode) // 'login', 'signup', 'forgot', 'reset'
  const isLogin = view === 'login'

  useEffect(() => {
    setView(mode)
  }, [mode])

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    role: 'student',
    branch: '',
    semester: ''
  })
  const [showPassword, setShowPassword] = useState(false)
  const { branches, semesters, branchesLoading, semestersLoading } =
    useAcademicOptions(formData.branch, formData.semester)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [loading, setLoading] = useState(false)

  // OTP verification state (signup / unverified account)
  const [showOtp, setShowOtp] = useState(false)
  const [pendingEmail, setPendingEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [otpLoading, setOtpLoading] = useState(false)
  const [otpError, setOtpError] = useState('')
  const [otpSuccess, setOtpSuccess] = useState('')
  const [resendCooldown, setResendCooldown] = useState(0)
  const cooldownRef = useRef(null)

  // Forgot / Reset password state
  const [forgotEmail, setForgotEmail] = useState('')
  const [resetOtp, setResetOtp] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showNewPassword, setShowNewPassword] = useState(false)
  const [resetLoading, setResetLoading] = useState(false)
  const [resetCooldown, setResetCooldown] = useState(0)
  const resetCooldownRef = useRef(null)

  // Google OAuth state
  const [googleLoading, setGoogleLoading] = useState(false)
  const [googleConfigNotice, setGoogleConfigNotice] = useState('')

  // Cleanup cooldown timers on unmount
  useEffect(() => {
    return () => {
      if (cooldownRef.current) clearInterval(cooldownRef.current)
      if (resetCooldownRef.current) clearInterval(resetCooldownRef.current)
    }
  }, [])

  const startResendCooldown = () => {
    setResendCooldown(60)
    if (cooldownRef.current) clearInterval(cooldownRef.current)
    cooldownRef.current = setInterval(() => {
      setResendCooldown((prev) => {
        if (prev <= 1) {
          clearInterval(cooldownRef.current)
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }

  const startResetCooldown = () => {
    setResetCooldown(60)
    if (resetCooldownRef.current) clearInterval(resetCooldownRef.current)
    resetCooldownRef.current = setInterval(() => {
      setResetCooldown((prev) => {
        if (prev <= 1) {
          clearInterval(resetCooldownRef.current)
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
      ...(name === 'branch' || name === 'role'
        ? { semester: '', ...(name === 'role' ? { branch: '' } : {}) }
        : {})
    }))
    setError('')
    setSuccess('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    if (!isLogin && formData.password.length < 8) {
      setError('Use at least 8 characters for your password.')
      return
    }
    setLoading(true)

    try {
      const response = await apiFetch(
        `/${isLogin ? 'login' : 'signup'}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            name: formData.name,
            email: formData.email,
            password: formData.password,
            role: formData.role,
            ...(formData.branch ? { branch: formData.branch } : {}),
            ...(formData.semester ? { semester: Number(formData.semester) } : {})
          })
        }
      )

      const data = await response.json()

      // Unverified login → redirect to OTP screen
      if (response.status === 403 && data.requires_verification) {
        setPendingEmail(data.email || formData.email)
        setOtp('')
        setOtpError('')
        setOtpSuccess('')
        setShowOtp(true)
        startResendCooldown()
        setLoading(false)
        return
      }

      if (!response.ok) {
        setError(data.error || data.message || 'Authentication failed. Please verify your details.')
        setLoading(false)
        return
      }

      // Signup → show OTP verification screen
      if (!isLogin && data.requires_verification) {
        setPendingEmail(data.email || formData.email)
        setOtp('')
        setOtpError('')
        setOtpSuccess('Account created! Check your email for a 6-digit verification code.')
        setShowOtp(true)
        startResendCooldown()
        setLoading(false)
        return
      }

      // Normal successful login
      onLoginSuccess({
        ...data.user,
        token: data.token,
        branch: data.user.branch || '',
        semester: data.user.semester || '',
        avatar: data.user.profile_photo_url ? apiUrl(data.user.profile_photo_url) : ''
      })
      setSuccess(isLogin ? 'You are signed in.' : 'Your account has been created.')
      window.setTimeout(() => onNavigate('/'), 500)
    } catch (requestError) {
      setError(requestError instanceof TypeError
        ? 'Unable to reach the U-NOTE backend. Check the deployment status or try again.'
        : requestError.message || 'Unable to complete the authentication request.')
    } finally {
      setLoading(false)
    }
  }

  const handleOtpSubmit = async (e) => {
    e.preventDefault()
    setOtpError('')
    setOtpSuccess('')
    if (!otp || otp.length !== 6 || !/^\d{6}$/.test(otp)) {
      setOtpError('Please enter the 6-digit code sent to your email.')
      return
    }
    setOtpLoading(true)
    try {
      const response = await apiFetch('/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: pendingEmail, otp })
      })
      const data = await response.json()
      if (!response.ok) {
        setOtpError(data.error || 'Verification failed. Please try again.')
        return
      }
      setOtpSuccess('Email verified! Signing you in…')
      onLoginSuccess({
        ...data.user,
        token: data.token,
        branch: data.user.branch || '',
        semester: data.user.semester || '',
        avatar: data.user.profile_photo_url ? apiUrl(data.user.profile_photo_url) : ''
      })
      window.setTimeout(() => onNavigate('/'), 600)
    } catch {
      setOtpError('Unable to reach the server. Please try again.')
    } finally {
      setOtpLoading(false)
    }
  }

  const handleResendOtp = async () => {
    if (resendCooldown > 0) return
    setOtpError('')
    setOtpSuccess('')
    try {
      const response = await apiFetch('/resend-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: pendingEmail })
      })
      const data = await response.json()
      if (!response.ok) {
        setOtpError(data.error || 'Failed to resend code. Please try again.')
        return
      }
      setOtpSuccess('A new code has been sent to your email.')
      startResendCooldown()
    } catch {
      setOtpError('Unable to resend code. Check your connection.')
    }
  }

  // ── Forgot Password handlers ──
  const handleForgotPasswordSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    if (!forgotEmail || !forgotEmail.trim()) {
      setError('Please enter your email address.')
      return
    }
    setLoading(true)
    try {
      const response = await apiFetch('/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: forgotEmail.trim() })
      })
      const data = await response.json()
      if (!response.ok) {
        setError(data.error || 'Unable to process password reset request. Please try again.')
        setLoading(false)
        return
      }
      setSuccess('If an account exists with this email, a 6-digit verification code has been sent.')
      setView('reset')
      startResetCooldown()
    } catch {
      setError('Unable to reach the server. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleResetPasswordSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    if (!resetOtp || resetOtp.length !== 6 || !/^\d{6}$/.test(resetOtp)) {
      setError('Please enter the 6-digit verification code sent to your email.')
      return
    }
    if (newPassword.length < 8) {
      setError('New password must be at least 8 characters long.')
      return
    }
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match. Please re-enter.')
      return
    }
    setResetLoading(true)
    try {
      const response = await apiFetch('/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: forgotEmail.trim(),
          otp: resetOtp.trim(),
          password: newPassword
        })
      })
      const data = await response.json()
      if (!response.ok) {
        setError(data.error || 'Password reset failed. Please check your verification code.')
        setResetLoading(false)
        return
      }
      setSuccess('Password reset successfully! Redirecting to login…')
      setFormData((prev) => ({ ...prev, email: forgotEmail.trim() }))
      window.setTimeout(() => {
        setView('login')
        setError('')
        setSuccess('Password updated. Please sign in with your new password.')
        setResetOtp('')
        setNewPassword('')
        setConfirmPassword('')
      }, 1500)
    } catch {
      setError('Unable to reach the server. Please try again.')
    } finally {
      setResetLoading(false)
    }
  }

  const handleResendResetOtp = async () => {
    if (resetCooldown > 0) return
    setError('')
    setSuccess('')
    try {
      const response = await apiFetch('/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: forgotEmail.trim() })
      })
      const data = await response.json()
      if (!response.ok) {
        setError(data.error || 'Unable to resend code.')
        return
      }
      setSuccess('A new verification code has been sent to your email.')
      startResetCooldown()
    } catch {
      setError('Unable to resend code. Check your connection.')
    }
  }

  // ── Google OAuth handler ──
  const handleGoogleCredential = async (credential) => {
    setGoogleLoading(true)
    setError('')
    setSuccess('')
    try {
      const response = await apiFetch('/google-login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ credential })
      })
      const data = await response.json()
      if (!response.ok) {
        setError(data.error || 'Google Sign-In failed. Please try again.')
        setGoogleLoading(false)
        return
      }
      onLoginSuccess({
        ...data.user,
        token: data.token,
        branch: data.user.branch || '',
        semester: data.user.semester || '',
        avatar: data.user.profile_photo_url ? apiUrl(data.user.profile_photo_url) : ''
      })
      setSuccess('Signed in with Google successfully.')
      window.setTimeout(() => onNavigate('/'), 500)
    } catch (err) {
      setError(err instanceof TypeError ? 'Unable to reach the server. Please check your connection.' : (err.message || 'Google Sign-In failed.'))
    } finally {
      setGoogleLoading(false)
    }
  }

  const handleGoogleSignInClick = () => {
    const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID
    if (!clientId || clientId.trim() === '') {
      setGoogleConfigNotice(
        'Google OAuth requires VITE_GOOGLE_CLIENT_ID configured in frontend environment and GOOGLE_CLIENT_ID in backend.'
      )
      return
    }

    setGoogleConfigNotice('')
    if (!window.google?.accounts?.id) {
      const script = document.createElement('script')
      script.src = 'https://accounts.google.com/gsi/client'
      script.async = true
      script.defer = true
      script.onload = () => {
        try {
          window.google.accounts.id.initialize({
            client_id: clientId.trim(),
            callback: (res) => {
              if (res.credential) handleGoogleCredential(res.credential)
            }
          })
          window.google.accounts.id.prompt()
        } catch {
          setError('Unable to initialize Google Sign-In prompt.')
        }
      }
      script.onerror = () => {
        setError('Failed to load Google Sign-In library. Check your internet connection.')
      }
      document.head.appendChild(script)
      return
    }

    try {
      window.google.accounts.id.initialize({
        client_id: clientId.trim(),
        callback: (res) => {
          if (res.credential) handleGoogleCredential(res.credential)
        }
      })
      window.google.accounts.id.prompt()
    } catch {
      setError('Unable to prompt Google Sign-In.')
    }
  }

  // ── OTP verification screen (Registration verification) ──
  if (showOtp) {
    return (
      <div className="auth-page-container">
        <div className="section-container">
          <div className="auth-form-wrapper otp-screen-wrapper">
            <div className="auth-header">
              <div className="auth-brand">
                <img src="/logo.png" alt="U-NOTE Logo" className="auth-brand-logo" />
              </div>
              <h1 className="auth-title">Verify your email</h1>
              <p className="auth-subtitle otp-hint-text">
                We sent a 6-digit code to <strong>{pendingEmail}</strong>.
                Enter it below to activate your account.
              </p>
            </div>

            <form className="auth-form" onSubmit={handleOtpSubmit}>
              <div className="form-group">
                <label htmlFor="otp">Verification Code</label>
                <input
                  id="otp"
                  type="text"
                  inputMode="numeric"
                  pattern="\d{6}"
                  maxLength={6}
                  className="form-control otp-input"
                  placeholder="000000"
                  value={otp}
                  onChange={(e) => {
                    setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))
                    setOtpError('')
                  }}
                  autoComplete="one-time-code"
                  autoFocus
                  required
                />
              </div>

              {otpError && (
                <p className="error-message auth-feedback auth-feedback-error" role="alert">
                  {otpError}
                </p>
              )}
              {otpSuccess && (
                <p className="auth-feedback auth-feedback-success" role="status">
                  {otpSuccess}
                </p>
              )}

              <div className="auth-actions">
                <button
                  type="submit"
                  className="btn btn-primary auth-submit-btn"
                  disabled={otpLoading || Boolean(otpSuccess && otpSuccess.includes('Signing'))}
                >
                  {otpLoading ? 'Verifying…' : 'Verify Email'}
                </button>
              </div>
            </form>

            <div className="auth-switch-footer">
              <p>
                Didn&apos;t receive the code?{' '}
                <button
                  type="button"
                  className={`text-link-btn otp-resend-btn${resendCooldown > 0 ? ' otp-resend-disabled' : ''}`}
                  onClick={handleResendOtp}
                  disabled={resendCooldown > 0}
                >
                  {resendCooldown > 0 ? `Resend in ${resendCooldown}s` : 'Resend code'}
                </button>
              </p>
              <p>
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => { setShowOtp(false); setOtpError(''); setOtpSuccess('') }}
                >
                  ← Back to {isLogin ? 'login' : 'sign up'}
                </button>
              </p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  // ── Forgot Password screen ──
  if (view === 'forgot') {
    return (
      <div className="auth-page-container">
        <div className="section-container">
          <div className="auth-form-wrapper">
            <div className="auth-header">
              <div className="auth-brand">
                <img src="/logo.png" alt="U-NOTE Logo" className="auth-brand-logo" />
              </div>
              <h1 className="auth-title">Forgot your password?</h1>
              <p className="auth-subtitle">
                Enter your registered email address. We&apos;ll send you a 6-digit verification code to reset your password.
              </p>
            </div>

            <form className="auth-form" onSubmit={handleForgotPasswordSubmit}>
              <div className="form-group">
                <label htmlFor="forgot-email">Email Address</label>
                <input
                  type="email"
                  id="forgot-email"
                  name="forgotEmail"
                  className="form-control"
                  placeholder="you@example.com"
                  value={forgotEmail}
                  onChange={(e) => {
                    setForgotEmail(e.target.value)
                    setError('')
                    setSuccess('')
                  }}
                  autoComplete="email"
                  required
                />
              </div>

              {error && (
                <p className="error-message auth-feedback auth-feedback-error" role="alert">
                  {error}
                </p>
              )}
              {success && (
                <p className="auth-feedback auth-feedback-success" role="status">
                  {success}
                </p>
              )}

              <div className="auth-actions">
                <button
                  type="submit"
                  className="btn btn-primary auth-submit-btn"
                  disabled={loading}
                >
                  {loading ? 'Sending code…' : 'Send Verification Code'}
                </button>
              </div>
            </form>

            <div className="auth-switch-footer">
              <p>
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => {
                    setView('login')
                    setError('')
                    setSuccess('')
                  }}
                >
                  ← Back to login
                </button>
              </p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  // ── Reset Password screen ──
  if (view === 'reset') {
    return (
      <div className="auth-page-container">
        <div className="section-container">
          <div className="auth-form-wrapper">
            <div className="auth-header">
              <div className="auth-brand">
                <img src="/logo.png" alt="U-NOTE Logo" className="auth-brand-logo" />
              </div>
              <h1 className="auth-title">Reset your password</h1>
              <p className="auth-subtitle">
                Enter the 6-digit code sent to <strong>{forgotEmail}</strong> and enter your new password.
              </p>
            </div>

            <form className="auth-form" onSubmit={handleResetPasswordSubmit}>
              <div className="form-group">
                <label htmlFor="reset-otp">Verification Code</label>
                <input
                  id="reset-otp"
                  type="text"
                  inputMode="numeric"
                  pattern="\d{6}"
                  maxLength={6}
                  className="form-control otp-input"
                  placeholder="000000"
                  value={resetOtp}
                  onChange={(e) => {
                    setResetOtp(e.target.value.replace(/\D/g, '').slice(0, 6))
                    setError('')
                  }}
                  autoComplete="one-time-code"
                  autoFocus
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="new-password">New Password</label>
                <div className="password-input-wrap">
                  <input
                    type={showNewPassword ? 'text' : 'password'}
                    id="new-password"
                    name="newPassword"
                    className="form-control"
                    placeholder="At least 8 characters"
                    value={newPassword}
                    onChange={(e) => {
                      setNewPassword(e.target.value)
                      setError('')
                    }}
                    autoComplete="new-password"
                    minLength={8}
                    maxLength={128}
                    required
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowNewPassword((v) => !v)}
                    aria-label={showNewPassword ? 'Hide password' : 'Show password'}
                  >
                    {showNewPassword ? 'Hide' : 'Show'}
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="confirm-password">Confirm New Password</label>
                <input
                  type={showNewPassword ? 'text' : 'password'}
                  id="confirm-password"
                  name="confirmPassword"
                  className="form-control"
                  placeholder="Re-enter your new password"
                  value={confirmPassword}
                  onChange={(e) => {
                    setConfirmPassword(e.target.value)
                    setError('')
                  }}
                  autoComplete="new-password"
                  minLength={8}
                  maxLength={128}
                  required
                />
              </div>

              {error && (
                <p className="error-message auth-feedback auth-feedback-error" role="alert">
                  {error}
                </p>
              )}
              {success && (
                <p className="auth-feedback auth-feedback-success" role="status">
                  {success}
                </p>
              )}

              <div className="auth-actions">
                <button
                  type="submit"
                  className="btn btn-primary auth-submit-btn"
                  disabled={resetLoading || Boolean(success && success.includes('Redirecting'))}
                >
                  {resetLoading ? 'Resetting password…' : 'Reset Password'}
                </button>
              </div>
            </form>

            <div className="auth-switch-footer">
              <p>
                Didn&apos;t receive the code?{' '}
                <button
                  type="button"
                  className={`text-link-btn otp-resend-btn${resetCooldown > 0 ? ' otp-resend-disabled' : ''}`}
                  onClick={handleResendResetOtp}
                  disabled={resetCooldown > 0}
                >
                  {resetCooldown > 0 ? `Resend in ${resetCooldown}s` : 'Resend code'}
                </button>
              </p>
              <p>
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => {
                    setView('login')
                    setError('')
                    setSuccess('')
                  }}
                >
                  ← Back to login
                </button>
              </p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  // ── Normal Login / Signup screen ──
  return (
    <div className="auth-page-container">
      <div className="section-container">
        <div className="auth-form-wrapper">
          <div className="auth-header">
            <div className="auth-brand">
              <img src="/logo.png" alt="U-NOTE Logo" className="auth-brand-logo" />
            </div>
            <h1 className="auth-title">
              {isLogin ? 'Welcome back' : 'Create your U-NOTE account'}
            </h1>
            <p className="auth-subtitle">
              {isLogin
                ? 'Sign in to find, share, and manage study resources.'
                : 'Join the RGPV community to find and share study resources.'}
            </p>
          </div>

          <div className="prototype-badge-box" style={{ backgroundColor: '#eff6ff', borderColor: '#bfdbfe' }}>
            <span className="prototype-badge-pill" style={{ backgroundColor: '#1d4ed8' }}>
              {isLogin ? 'Student & Teacher Portal' : 'Community Account'}
            </span>
            <p className="prototype-badge-text" style={{ color: '#1e40af' }}>
              {isLogin ? 'Use your registered email and password.' : 'Choose the account type that describes you.'}
            </p>
          </div>

          <form className="auth-form" onSubmit={handleSubmit}>
            {!isLogin && (
              <div className="form-group">
                <label htmlFor="name">Full Name</label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  className="form-control"
                  placeholder="Enter your full name"
                  value={formData.name}
                  onChange={handleChange}
                  autoComplete="name"
                  maxLength={100}
                  required
                />
              </div>
            )}

            <div className="form-group">
              <label htmlFor="email">Email Address</label>
              <input
                type="email"
                id="email"
                name="email"
                className="form-control"
                placeholder="you@example.com"
                value={formData.email}
                onChange={handleChange}
                autoComplete="email"
                required
              />
            </div>

            <div className="form-group">
              <div className="form-label-row">
                <label htmlFor="password">Password</label>
                {isLogin && (
                  <button
                    type="button"
                    className="text-link-btn forgot-password-link"
                    onClick={() => {
                      setError('')
                      setSuccess('')
                      setForgotEmail(formData.email || '')
                      setView('forgot')
                    }}
                  >
                    Forgot password?
                  </button>
                )}
              </div>
              <div className="password-input-wrap">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="password"
                  name="password"
                  className="form-control"
                  placeholder={isLogin ? 'Enter your password' : 'At least 8 characters'}
                  value={formData.password}
                  onChange={handleChange}
                  autoComplete={isLogin ? 'current-password' : 'new-password'}
                  minLength={isLogin ? undefined : 8}
                  maxLength={128}
                  required
                />
                <button
                  type="button"
                  className="password-toggle-btn"
                  onClick={() => setShowPassword((visible) => !visible)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
            </div>

            {!isLogin && (
              <>
                <div className="form-group">
                  <label htmlFor="role">Account type</label>
                  <select
                    id="role"
                    name="role"
                    className="form-control"
                    value={formData.role}
                    onChange={handleChange}
                    required
                  >
                    <option value="student">Student</option>
                    <option value="teacher">Teacher</option>
                  </select>
                </div>
                {formData.role === 'student' && (
                  <div className="form-row">
                    <div className="form-group">
                      <label htmlFor="branch">Branch *</label>
                      <select
                        id="branch"
                        name="branch"
                        className="form-control"
                        value={formData.branch}
                        onChange={handleChange}
                        disabled={branchesLoading}
                        required
                      >
                        <option value="" disabled>
                          {branchesLoading ? 'Loading branches...' : 'Select branch'}
                        </option>
                        {branches.map((branch) => (
                          <option key={branch.id} value={branch.name}>{branch.name}</option>
                        ))}
                      </select>
                    </div>

                    <div className="form-group">
                      <label htmlFor="semester">Semester *</label>
                      <select
                        id="semester"
                        name="semester"
                        className="form-control"
                        value={formData.semester}
                        onChange={handleChange}
                        required
                        disabled={!formData.branch || semestersLoading || branchesLoading}
                      >
                        <option value="" disabled>
                          {!formData.branch
                            ? 'Select branch first'
                            : semestersLoading
                              ? 'Loading semesters...'
                              : 'Select semester'}
                        </option>
                        {semesters.map((sem) => (
                          <option key={sem.id} value={sem.number}>
                            {sem.name}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                )}
              </>
            )}

            {error && (
              <p className="error-message auth-feedback auth-feedback-error" role="alert">
                {error}
              </p>
            )}
            {success && (
              <p className="auth-feedback auth-feedback-success" role="status">
                {success}
              </p>
            )}

            <div className="auth-actions">
              <button
                type="submit"
                className="btn btn-primary auth-submit-btn"
                disabled={loading || Boolean(success)}
              >
                {loading ? 'Please wait...' : (isLogin ? 'Log In' : 'Create Account')}
              </button>
            </div>
          </form>

          {/* Continue with Google */}
          <div className="auth-divider">
            <span>or</span>
          </div>

          <button
            type="button"
            className="google-auth-btn"
            onClick={handleGoogleSignInClick}
            disabled={loading || googleLoading}
          >
            <svg className="google-icon" viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" />
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
            </svg>
            <span>{googleLoading ? 'Connecting to Google…' : 'Continue with Google'}</span>
          </button>

          {googleConfigNotice && (
            <p className="auth-feedback" style={{ marginTop: '0.75rem', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              ℹ️ {googleConfigNotice}
            </p>
          )}

          <div className="auth-switch-footer">
            {isLogin ? (
              <p>
                Don&apos;t have an account yet?{' '}
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => {
                    setError('')
                    setSuccess('')
                    onNavigate('/signup')
                  }}
                >
                  Sign Up
                </button>
              </p>
            ) : (
              <p>
                Already have an account?{' '}
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => {
                    setError('')
                    setSuccess('')
                    onNavigate('/login')
                  }}
                >
                  Log In
                </button>
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default AuthPages
