import { useState } from 'react'
import { apiFetch } from '../api'

const REPORT_REASONS = [
  { value: 'Inappropriate Content', label: 'Inappropriate Content' },
  { value: 'Incorrect or Outdated Material', label: 'Incorrect or Outdated Material' },
  { value: 'Duplicate Resource', label: 'Duplicate Resource' },
  { value: 'Broken or Corrupted File', label: 'Broken or Corrupted File' },
  { value: 'Copyright Violation', label: 'Copyright Violation' },
  { value: 'Other Reason', label: 'Other Reason' }
]

function ReportResourceModal({ resource, user, onClose, onSuccess }) {
  const [reason, setReason] = useState(REPORT_REASONS[0].value)
  const [details, setDetails] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccessMsg('')

    if (!user?.token) {
      setError('Please log in to report this resource.')
      return
    }

    if (!reason.trim()) {
      setError('Please choose a reason for reporting.')
      return
    }

    setSubmitting(true)
    try {
      const response = await apiFetch(`/resources/${resource.id}/reports`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reason: reason.trim(),
          details: details.trim()
        })
      }, user.token)

      const data = await response.json()
      if (response.ok && data.success) {
        setSuccessMsg(data.message || 'Report submitted successfully. Thank you for keeping U-NOTE safe!')
        if (onSuccess) onSuccess()
        setTimeout(() => {
          onClose()
        }, 1800)
      } else {
        setError(data.message || 'Failed to submit report. Please try again.')
      }
    } catch {
      setError('Network error while reporting resource. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal-card report-modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '480px' }}>
        <button
          type="button"
          className="modal-close-icon"
          onClick={onClose}
          aria-label="Close modal"
        >
          &times;
        </button>

        <div className="modal-header">
          <h2 className="modal-title" style={{ color: '#ef4444', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span>🚩</span> Report Resource
          </h2>
          <p className="modal-subtitle" style={{ fontSize: '0.9rem', color: '#64748b', marginTop: '0.25rem' }}>
            Help our moderators keep study materials accurate, complete, and safe.
          </p>
        </div>

        {successMsg ? (
          <div className="alert-banner alert-success" style={{ margin: '1.25rem 0' }}>
            {successMsg}
          </div>
        ) : (
          <form onSubmit={handleSubmit} style={{ marginTop: '1rem' }}>
            {error && (
              <div className="alert-banner alert-danger" style={{ marginBottom: '1rem' }}>
                {error}
              </div>
            )}

            <div className="form-group" style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', fontWeight: 600, marginBottom: '0.4rem', fontSize: '0.9rem' }}>
                Resource
              </label>
              <div className="report-resource-info-box">
                <strong>{resource?.title}</strong>
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: '1rem' }}>
              <label htmlFor="report-reason" style={{ display: 'block', fontWeight: 600, marginBottom: '0.4rem', fontSize: '0.9rem' }}>
                Reason for Reporting <span style={{ color: '#ef4444' }}>*</span>
              </label>
              <select
                id="report-reason"
                className="form-control"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
              >
                {REPORT_REASONS.map((r) => (
                  <option key={r.value} value={r.value}>{r.label}</option>
                ))}
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '1.25rem' }}>
              <label htmlFor="report-details" style={{ display: 'block', fontWeight: 600, marginBottom: '0.4rem', fontSize: '0.9rem' }}>
                Additional Details (Optional)
              </label>
              <textarea
                id="report-details"
                className="form-control"
                rows={3}
                placeholder="Describe what is wrong with this resource (e.g. page 4 is missing, copyright issue, wrong syllabus)..."
                value={details}
                onChange={(e) => setDetails(e.target.value)}
                maxLength={1000}
              />
              <span style={{ fontSize: '0.75rem', color: '#94a3b8', display: 'block', textAlign: 'right', marginTop: '0.2rem' }}>
                {details.length}/1000
              </span>
            </div>

            <div className="modal-footer" style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={onClose}
                disabled={submitting}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="btn"
                disabled={submitting}
                style={{
                  background: '#ef4444',
                  color: '#ffffff',
                  border: 'none',
                  padding: '0.55rem 1.25rem',
                  borderRadius: '8px',
                  fontWeight: 600,
                  cursor: submitting ? 'not-allowed' : 'pointer'
                }}
              >
                {submitting ? 'Submitting...' : 'Submit Report'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  )
}

export default ReportResourceModal
