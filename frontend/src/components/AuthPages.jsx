import { useState, useEffect, useRef } from 'react'
import { apiFetch, apiUrl } from '../api'
import { useAcademicOptions } from '../hooks/useAcademicOptions'

function AuthPages({ mode = 'login', onNavigate, onLoginSuccess }) {
  const isLogin = mode === 'login'
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

  // OTP verification state
  const [showOtp, setShowOtp] = useState(false)
  const [pendingEmail, setPendingEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [otpLoading, setOtpLoading] = useState(false)
  const [otpError, setOtpError] = useState('')
  const [otpSuccess, setOtpSuccess] = useState('')
  const [resendCooldown, setResendCooldown] = useState(0)
  const cooldownRef = useRef(null)

  // Cleanup cooldown timer on unmount
  useEffect(() => {
    return () => {
      if (cooldownRef.current) clearInterval(cooldownRef.current)
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

  // ── OTP verification screen ──
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

  // ── Normal login / signup form ──
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
              <label htmlFor="password">Password</label>
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
                {formData.role === 'student' && <div className="form-row">
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
              </div>}
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

          <div className="auth-switch-footer">
            {isLogin ? (
              <p>
                Don&apos;t have an account yet?{' '}
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => { setError(''); onNavigate('/signup') }}
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
                  onClick={() => { setError(''); onNavigate('/login') }}
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
