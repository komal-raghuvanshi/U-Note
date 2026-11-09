import { useState } from 'react'

function HelpPage({ onNavigate }) {
  const [activeFaq, setActiveFaq] = useState(null)

  const faqs = [
    {
      q: 'How does U-NOTE organize study materials?',
      a: 'U-NOTE organizes all academic materials according to the official RGPV university hierarchy: Branch &rarr; Semester &rarr; Subject &rarr; Unit. This allows you to pinpoint the exact unit you need for exams without digging through disorganized groups.'
    },
    {
      q: 'How do I find notes for my specific subject and unit?',
      a: 'Click on the "Resources" link in the top navigation bar. You can use the search bar to enter your subject name, or use the dropdown filters to choose your Branch, Semester, and an available unit for that subject.'
    },
    {
      q: 'What types of resources are supported?',
      a: 'U-NOTE supports Handwritten Notes, PDF Notes, Class Notes, Previous Year Question Papers (PYQs), Important Exam Questions, YouTube Lecture Playlists, and Teacher Resources.'
    },
    {
      q: 'How can I contribute or share my notes?',
      a: 'Click "Share a Resource", choose your branch, semester, subject, and unit, then upload a PDF or image. YouTube resource types can be submitted as a link. Contributions help build an open community of study materials for all RGPV students.'
    },
    {
      q: 'Are the resources on U-NOTE free to access?',
      a: 'Yes, U-NOTE is developed as a student-first academic resource platform. All study materials, PYQs, and lecture links are completely open and accessible to all students.'
    }
  ]

  const toggleFaq = (index) => {
    setActiveFaq(activeFaq === index ? null : index)
  }

  return (
    <div className="help-page-container">
      <div className="section-container">
        <div className="page-header-box text-center">
          
          <h1 className="page-title">Help &amp; Knowledge Base</h1>
          <p className="page-subtitle">
            Find answers to common questions about finding, using, and sharing RGPV study resources.
          </p>
        </div>

        {/* Quick Instructions Cards */}
        <div className="help-steps-grid">
          <div className="help-step-card">
            <span className="step-badge">1</span>
            <h3>Locate Resources</h3>
            <p>
              Use the <strong>Resources</strong> page to filter by Branch, Semester, Subject, and Unit to find exact notes.
            </p>
          </div>

          <div className="help-step-card">
            <span className="step-badge">2</span>
            <h3>Review Details</h3>
            <p>
              Click on any resource card to inspect its subject, unit number, verified notes category, and file details.
            </p>
          </div>

          <div className="help-step-card">
            <span className="step-badge">3</span>
            <h3>Share Material</h3>
            <p>
              Upload class notes, PYQs, or teacher slides via <strong>Share Resources</strong> to assist your batchmates.
            </p>
          </div>
        </div>

        {/* FAQs Section */}
        <div className="faq-section-wrapper">
          <h2 className="faq-section-title">Frequently Asked Questions</h2>
          <div className="faq-list">
            {faqs.map((faq, index) => (
              <div
                key={index}
                className={`faq-item ${activeFaq === index ? 'active' : ''}`}
              >
                <button
                  type="button"
                  className="faq-question-btn"
                  onClick={() => toggleFaq(index)}
                >
                  <span>{faq.q}</span>
                  <span className="faq-toggle-icon">
                    {activeFaq === index ? '−' : '+'}
                  </span>
                </button>
                {activeFaq === index && (
                  <div className="faq-answer">
                    <p dangerouslySetInnerHTML={{ __html: faq.a }}></p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Still Need Help Banner */}
        <div className="need-help-banner">
          <div>
            <h3>Still have questions or found a bug?</h3>
            <p>Reach out to the U-NOTE project team through our contact page.</p>
          </div>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => onNavigate('/contact')}
          >
            Contact Us
          </button>
        </div>
      </div>
    </div>
  )
}

export default HelpPage
