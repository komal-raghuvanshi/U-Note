import { useState } from 'react'
import { apiFetch } from '../api'
import { useAcademicOptions } from '../hooks/useAcademicOptions'

function AuthPages({ mode = 'login', onNavigate, onLoginSuccess }) {
  const isLogin = mode === 'login'
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    branch: '',
    semester: ''
  })
  const { branches, semesters, branchesLoading, semestersLoading } =
    useAcademicOptions(formData.branch, formData.semester)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
      ...(name === 'branch' ? { semester: '' } : {})
    }))
    setError('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
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
            branch: formData.branch,
            semester: Number(formData.semester)
          })
        }
      )

      const data = await response.json()

      if (!response.ok) {
        setError(data.error || data.message || 'Authentication failed. Please verify your details.')
        setLoading(false)
        return
      }

      onLoginSuccess({
        ...data.user,
        token: data.token,
        branch: data.user.branch || '',
        semester: data.user.semester || ''
      })

      onNavigate('/')
    } catch {
      setError('Unable to connect to the backend server. Please verify Flask is running on port 5000.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-page-container">
      <div className="section-container">
        <div className="auth-form-wrapper">
          <div className="auth-header">
            <h1 className="auth-title">
              {isLogin ? 'Log in to U-NOTE' : 'Create Student Account'}
            </h1>
            <p className="auth-subtitle">
              {isLogin
                ? 'Access your uploaded notes, profile, and study materials.'
                : 'Join the JIT Borawan & RGPV community to share and access study resources.'}
            </p>
          </div>

          <div className="prototype-badge-box" style={{ backgroundColor: '#eff6ff', borderColor: '#bfdbfe' }}>
            <span className="prototype-badge-pill" style={{ backgroundColor: '#1d4ed8' }}>Portal</span>
            <p className="prototype-badge-text" style={{ color: '#1e40af' }}>
              Sign in or create an account to manage your study resources.
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
                  placeholder="e.g. Komal Raghuvanshi"
                  value={formData.name}
                  onChange={handleChange}
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
                placeholder="student@jitborawan.com or gmail"
                value={formData.email}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password</label>
              <input
                type="password"
                id="password"
                name="password"
                className="form-control"
                placeholder="Enter password"
                value={formData.password}
                onChange={handleChange}
                required
              />
            </div>

            {!isLogin && (
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="branch">Branch</label>
                  <select
                    id="branch"
                    name="branch"
                    className="form-control"
                    value={formData.branch}
                    onChange={handleChange}
                    required
                  >
                    <option value="" disabled>Select branch</option>
                    {branches.map((branch) => (
                      <option key={branch.id} value={branch.name}>{branch.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="semester">Semester</label>
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

            {error && (
              <p className="error-message" role="alert" style={{ color: '#dc2626', fontWeight: 500, margin: '0.25rem 0' }}>
                {error}
              </p>
            )}

            <div className="auth-actions">
              <button
                type="submit"
                className="btn btn-primary auth-submit-btn"
                disabled={loading}
              >
                {loading ? 'Processing...' : (isLogin ? 'Log In' : 'Create Account')}
              </button>

            </div>
          </form>

          <div className="auth-switch-footer">
            {isLogin ? (
              <p>
                Don't have an account yet?{' '}
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
