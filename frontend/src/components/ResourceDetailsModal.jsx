import { useState, useEffect } from 'react'
import { apiFetch, apiUrl } from '../api'

function ResourceDetailsModal({ resource, onClose, user, onRatingSubmitted }) {
  const [ratingData, setRatingData] = useState({
    avg_rating: resource?.avg_rating || null,
    rating_count: resource?.rating_count || 0,
    ratings: [],
    user_rating: null
  })
  const [loadingRatings, setLoadingRatings] = useState(true)
  const [selectedStars, setSelectedStars] = useState(5)
  const [hoverStars, setHoverStars] = useState(0)
  const [reviewText, setReviewText] = useState('')
  const [submittingRating, setSubmittingRating] = useState(false)
  const [ratingError, setRatingError] = useState('')
  const [ratingSuccess, setRatingSuccess] = useState('')
  const [ratingsLoadError, setRatingsLoadError] = useState('')
  const [isSaved, setIsSaved] = useState(false)
  const [savingResource, setSavingResource] = useState(false)

  useEffect(() => {
    if (!resource?.id) return
    let ignore = false

    async function loadRatings() {
      setLoadingRatings(true)
      setRatingsLoadError('')
      try {
        const res = await apiFetch(`/resources/${resource.id}/ratings`, {}, user?.token)
        const data = await res.json()
        if (!res.ok) throw new Error(data.message || 'Unable to load reviews.')
        if (!ignore && data.success) {
          setRatingData({
            avg_rating: data.avg_rating,
            rating_count: data.rating_count,
            ratings: data.ratings || [],
            user_rating: data.user_rating
          })
          if (data.user_rating) {
            setSelectedStars(data.user_rating.rating)
            setReviewText(data.user_rating.review || '')
          }
        }
      } catch (error) {
        if (!ignore) setRatingsLoadError(error.message || 'Unable to load reviews.')
      } finally {
        if (!ignore) setLoadingRatings(false)
      }
    }

    loadRatings()
    return () => { ignore = true }
  }, [resource?.id, user?.token])

  useEffect(() => {
    if (!resource?.id || !user?.token) {
      setIsSaved(false)
      return undefined
    }

    let ignore = false
    apiFetch(`/resources/${resource.id}/saved`, {}, user.token)
      .then(async (response) => {
        const data = await response.json()
        if (!response.ok) throw new Error(data.message || 'Unable to check saved status.')
        if (!ignore) setIsSaved(Boolean(data.saved))
      })
      .catch((error) => {
        if (!ignore) setRatingError(error.message || 'Unable to check saved status.')
      })
    return () => { ignore = true }
  }, [resource?.id, user?.token])

  const handleToggleSaved = async () => {
    if (!user?.token) {
      setRatingError('Please log in to save this study resource.')
      return
    }
    setSavingResource(true)
    setRatingError('')
    try {
      const response = await apiFetch(`/resources/${resource.id}/saved`, {
        method: isSaved ? 'DELETE' : 'POST'
      }, user.token)
      const data = await response.json()
      if (!response.ok) throw new Error(data.message || 'Unable to update saved resources.')
      setIsSaved(Boolean(data.saved))
    } catch (error) {
      setRatingError(error.message || 'Unable to update saved resources.')
    } finally {
      setSavingResource(false)
    }
  }

  const handleStarSubmit = async (e) => {
    e.preventDefault()
    setRatingError('')
    setRatingSuccess('')

    if (!user?.id) {
      setRatingError('Please log in to rate this study resource.')
      return
    }

    setSubmittingRating(true)
    try {
      const res = await apiFetch(`/resources/${resource.id}/ratings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          rating: selectedStars,
          review: reviewText.trim()
        })
      }, user.token)

      const data = await res.json()
      if (res.ok && data.success) {
        setRatingSuccess('Thank you! Your rating has been recorded.')
        setRatingData((prev) => ({
          ...prev,
          avg_rating: data.avg_rating,
          rating_count: data.rating_count,
          user_rating: { rating: selectedStars, review: reviewText.trim() }
        }))
        if (onRatingSubmitted) {
          onRatingSubmitted(resource.id, data.avg_rating, data.rating_count)
        }
      } else {
        setRatingError(data.message || 'Failed to submit rating.')
      }
    } catch {
      setRatingError('Unable to connect to server.')
    } finally {
      setSubmittingRating(false)
    }
  }

  if (!resource) return null

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '640px' }}>
        <button
          type="button"
          className="modal-close-icon"
          onClick={onClose}
          aria-label="Close modal"
        >
          &times;
        </button>

        <div className="modal-header">
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap', marginBottom: '0.4rem' }}>
            <span className="modal-type-badge">{resource.type}</span>
            {resource.uploader_role === 'teacher' && (
              <span className="faculty-badge">Faculty Verified</span>
            )}
          </div>
          <h2 className="modal-title">{resource.title}</h2>
        </div>

        <div className="modal-body" style={{ maxHeight: 'calc(85vh - 180px)', overflowY: 'auto' }}>
          {/* Metadata Grid */}
          <div className="modal-meta-grid">
            <div className="meta-item">
              <span className="meta-label">Branch</span>
              <span className="meta-value">{resource.branch}</span>
            </div>

            <div className="meta-item">
              <span className="meta-label">Semester</span>
              <span className="meta-value">Semester {resource.semester}</span>
            </div>

            <div className="meta-item">
              <span className="meta-label">Subject</span>
              <span className="meta-value">
                {resource.subject_code ? `${resource.subject_code} - ` : ''}
                {resource.subject}
              </span>
            </div>

            <div className="meta-item">
              <span className="meta-label">Unit Scope</span>
              <span className="meta-value">
                {resource.unit_label || (resource.unit ? `Unit ${resource.unit}` : 'All Units')}
              </span>
            </div>
          </div>

          {resource.uploader_name && (
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>
              Shared by <strong>{resource.uploader_name}</strong> ({resource.uploader_role === 'teacher' ? 'Faculty Member' : 'Student'})
            </p>
          )}

          {resource.description && (
            <div className="modal-note-box" style={{ margin: '1rem 0' }}>
              <p>
                <strong>Description:</strong> {resource.description}
              </p>
            </div>
          )}

          {/* Ratings & Reviews Section */}
          <div className="modal-rating-section">
            <div className="rating-summary-header">
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700, margin: 0, color: 'var(--text-dark)' }}>
                Student &amp; Faculty Ratings
              </h3>
              <div className="rating-badge-large">
                <span className="star-icon" style={{ color: '#f59e0b', fontSize: '1.25rem' }}>★</span>
                <span style={{ fontWeight: 700, fontSize: '1.1rem' }}>
                  {ratingData.avg_rating !== null ? `${ratingData.avg_rating} / 5.0` : 'Not yet rated'}
                </span>
                <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                  ({ratingData.rating_count} {ratingData.rating_count === 1 ? 'review' : 'reviews'})
                </span>
              </div>
            </div>

            {ratingsLoadError && <p className="error-message" role="alert">{ratingsLoadError}</p>}

            {/* Interactive Rating Form */}
            {user ? (
              <form onSubmit={handleStarSubmit} className="rating-interactive-box">
                <p style={{ fontSize: '0.88rem', fontWeight: 600, marginBottom: '0.5rem', color: 'var(--text-dark)' }}>
                  {ratingData.user_rating ? 'Update Your Rating & Feedback:' : 'Rate This Study Material:'}
                </p>

                <div className="star-picker-row">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <button
                      key={star}
                      type="button"
                      className="star-pick-btn"
                      onMouseEnter={() => setHoverStars(star)}
                      onMouseLeave={() => setHoverStars(0)}
                      onClick={() => setSelectedStars(star)}
                      aria-label={`${star} star`}
                    >
                      <span style={{ color: (hoverStars || selectedStars) >= star ? '#f59e0b' : '#cbd5e1' }}>
                        ★
                      </span>
                    </button>
                  ))}
                  <span style={{ marginLeft: '0.5rem', fontSize: '0.85rem', fontWeight: 600, color: '#475569' }}>
                    {selectedStars} / 5 Stars
                  </span>
                </div>

                <textarea
                  className="form-control"
                  rows={2}
                  placeholder="Share a brief comment (e.g. Cleared my concepts for unit 3, well written handwriting)"
                  value={reviewText}
                  onChange={(e) => setReviewText(e.target.value)}
                  style={{ marginTop: '0.6rem', fontSize: '0.88rem' }}
                />

                {ratingError && <p className="error-message" style={{ marginTop: '0.4rem' }}>{ratingError}</p>}
                {ratingSuccess && <p className="success-message" style={{ color: '#15803d', fontSize: '0.85rem', marginTop: '0.4rem' }}>{ratingSuccess}</p>}

                <div style={{ marginTop: '0.6rem', textAlign: 'right' }}>
                  <button type="submit" className="btn btn-secondary btn-sm" disabled={submittingRating}>
                    {submittingRating ? 'Saving...' : ratingData.user_rating ? 'Update Review' : 'Submit Rating'}
                  </button>
                </div>
              </form>
            ) : (
              <div className="login-to-rate-notice">
                <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                  Log in to rate this note and help your fellow classmates find the best materials.
                </p>
              </div>
            )}

            {/* List of recent reviews */}
            <div className="reviews-list-container" style={{ marginTop: '1rem' }}>
              <h4 style={{ fontSize: '0.92rem', fontWeight: 700, marginBottom: '0.5rem', color: 'var(--text-muted)' }}>
                User Reviews ({ratingData.ratings.length})
              </h4>
              {loadingRatings ? (
                <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Loading reviews...</p>
              ) : ratingData.ratings.length === 0 ? (
                <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  No written reviews yet. Be the first to leave feedback!
                </p>
              ) : (
                <div className="reviews-scroll-box">
                  {ratingData.ratings.map((rev) => (
                    <div key={rev.rating_id} className="review-item-card">
                      <div className="review-item-top">
                        <span className="reviewer-name">
                          {rev.user_name}
                          {rev.user_role === 'teacher' && <span className="faculty-mini-tag">Faculty</span>}
                        </span>
                        <span className="review-stars">
                          {'★'.repeat(rev.rating)}
                          {'☆'.repeat(5 - rev.rating)}
                        </span>
                      </div>
                      {rev.review && <p className="review-item-text">{rev.review}</p>}
                      <span className="review-item-date">
                        {rev.created_at ? new Date(rev.created_at).toLocaleDateString() : ''}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Modal Footer Actions */}
        <div className="modal-footer" style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end', alignItems: 'center', flexWrap: 'wrap' }}>
          {user && (
            <button type="button" className="btn btn-secondary" onClick={handleToggleSaved} disabled={savingResource}>
              {savingResource ? 'Saving...' : isSaved ? 'Remove Saved' : 'Save Resource'}
            </button>
          )}
          {resource.filename && (
            <>
              <a
                href={apiUrl(`/uploads/${resource.filename}`)}
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-secondary"
                style={{ textDecoration: 'none' }}
              >
                View File
              </a>
              <a
                href={apiUrl(`/download/${resource.filename}`)}
                download
                className="btn btn-outline"
                style={{ textDecoration: 'none' }}
              >
                Download
              </a>
            </>
          )}
          {resource.is_external && resource.resource_url && (
            <a
              href={resource.resource_url}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-secondary"
              style={{ textDecoration: 'none' }}
            >
              Open External Link &rarr;
            </a>
          )}
          <button type="button" className="btn btn-primary" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  )
}

export default ResourceDetailsModal
