import { useState } from 'react'
import emailjs from '@emailjs/browser'

function ContactPage() {
  const [submitted, setSubmitted] = useState(false)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: ''
  })

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e) => {
  e.preventDefault()
  setError('')
  setSending(true)

  try {
    await emailjs.send(
      'service_66gjvjn',
      'template_56dcd4g',
      {
        name: formData.name,
        email: formData.email,
        subject: formData.subject,
        message: formData.message
      },
      {
        publicKey: 'ihPR3g0XLoDIxbsc8'
      }
    )

    setSubmitted(true)
  } catch (err) {
    console.error('Email sending failed:', err)
    setError('Unable to send your message right now. Please try again later.')
  } finally {
    setSending(false)
  }
}

  return (
    <div className="contact-page-container">
      <div className="section-container">
        <div className="page-header-box text-center">
          <h1 className="page-title">Contact U-NOTE Team</h1>
          <p className="page-subtitle">
            Have suggestions, missing subject requests, or project feedback? Send us a message!
          </p>
        </div>

        <div className="contact-card-wrapper">
          {submitted ? (
            <div className="submission-success-card">
              <h3>Message Sent Successfully!</h3>
              <p>
                Thank you for contacting us, <strong>{formData.name}</strong>.
              </p>
              <p className="success-note">
                Your message has been sent to the U-NOTE team. We appreciate your feedback!
              </p>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => {
                  setSubmitted(false)
                  setError('')
                  setFormData({
                    name: '',
                    email: '',
                    subject: '',
                    message: ''
                  })
                }}
              >
                Send Another Message
              </button>
            </div>
          ) : (
            <form className="contact-form" onSubmit={handleSubmit}>
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="name">Your Name</label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    className="form-control"
                    placeholder="Enter your full name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="email">Email Address</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    className="form-control"
                    placeholder="name@college.edu or gmail"
                    value={formData.email}
                    onChange={handleChange}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="subject">Subject / Inquiry Type</label>
                <input
                  type="text"
                  id="subject"
                  name="subject"
                  className="form-control"
                  placeholder="e.g. Request new subject notes or report broken link"
                  value={formData.subject}
                  onChange={handleChange}
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="message">Message</label>
                <textarea
                  id="message"
                  name="message"
                  rows="5"
                  className="form-control"
                  placeholder="Describe your inquiry, feedback, or resource request..."
                  value={formData.message}
                  onChange={handleChange}
                  required
                ></textarea>
              </div>

              {error && (
                <p className="error-message" role="alert">
                  {error}
                </p>
              )}

              <div className="form-button-row">
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={sending}
                >
                  {sending ? 'Sending...' : 'Send Message'}
                </button>
              </div>
            </form>
          )}

          <div className="contact-info-footer">
            <div className="info-item">
              <span className="info-title">College Minor Project</span>
              <span className="info-sub">RGPV Affiliated Colleges</span>
            </div>
            <div className="info-item">
              <span className="info-title">Platform Scope</span>
              <span className="info-sub">Academic Study Resources &amp; Notes</span>
            </div>
            <div className="info-item">
              <span className="info-title">Location</span>
              <span className="info-sub">Bhopal, Madhya Pradesh</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ContactPage
