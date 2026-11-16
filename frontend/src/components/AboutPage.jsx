const teamMembers = [
  {
    name: 'Komal Raghuvanshi',
    role: '3rd Year | B.Tech AI & ML | Frontend & Backend Developer',
    photoUrl: '/team/Komal_Raghuvanshi_passport.jpeg',
    linkedinUrl: 'https://www.linkedin.com/in/komalraghuvanshi16',
    githubUrl: 'https://github.com/komal-raghuvanshi',
  },
  {
    name: 'Khushi Kushwah',
    role: '3rd Year | B.Tech AI & ML | Database Developer',
    photoUrl: '/team/Khushi_Kushwah.jpeg',
    linkedinUrl: 'https://www.linkedin.com/in/khushi-kushwah-2a8401331',
    githubUrl: 'https://github.com/kushwahkhushi300-max',
  },
  {
    name: 'Sakshi Yadav',
    role: '3rd Year | B.Tech AI & ML | Database Documentation',
    photoUrl: '/team/sakshi_yadav.jpeg',
    linkedinUrl: 'https://www.linkedin.com/in/sakshi-yadav-86b500331?utm_source=share_via&utm_content=profile&utm_medium=member_android',
    githubUrl: 'https://github.com/sakshiyadav18-bot',
  },
  { name: 'Vishakha Solanki', role: '3rd Year | B.Tech AI & ML | Backend Developer', photoUrl: '/team/vishakha_solanki.png', linkedinUrl: 'https://www.linkedin.com/in/vishakha-solanki-1775a832a?utm_source=share_via&utm_content=profile&utm_medium=member_android', githubUrl: 'https://github.com/solankivishakha1808-ux' },
]

const offerings = [
  { title: 'Study Notes', icon: 'notes' },
  { title: 'PDF Resources', icon: 'pdf' },
  { title: 'Previous Year Papers', icon: 'papers' },
  { title: 'Important Questions', icon: 'questions' },
  { title: 'Peer-to-Peer Sharing', icon: 'sharing' },
  { title: 'Resource Requests', icon: 'requests' },
]

function OfferingIcon({ name }) {
  const paths = {
    notes: (
      <>
        <path d="M7 3.75h7l4 4v12.5H7a2 2 0 0 1-2-2v-12.5a2 2 0 0 1 2-2Z" />
        <path d="M14 3.75v4h4M8.5 12h6M8.5 15.5h6" />
      </>
    ),
    pdf: (
      <>
        <path d="M7 3.75h7l4 4v12.5H7a2 2 0 0 1-2-2v-12.5a2 2 0 0 1 2-2Z" />
        <path d="M14 3.75v4h4M8.5 12h6M8.5 15.5h3" />
      </>
    ),
    papers: (
      <>
        <path d="M4.5 5.5h10a2 2 0 0 1 2 2v12h-10a2 2 0 0 1-2-2v-12Z" />
        <path d="M16.5 8h2a1 1 0 0 1 1 1v10.5h-3M8 9h5M8 12.5h5M8 16h3" />
      </>
    ),
    questions: (
      <>
        <circle cx="12" cy="12" r="8.5" />
        <path d="M9.8 9a2.3 2.3 0 1 1 3.8 1.7c-1 .9-1.6 1.3-1.6 2.8M12 16.5v.1" />
      </>
    ),
    sharing: (
      <>
        <circle cx="8" cy="7" r="2.5" />
        <circle cx="16.5" cy="8.5" r="2" />
        <path d="M3.5 18a4.5 4.5 0 0 1 9 0M14 14a3.5 3.5 0 0 1 6.5 2" />
      </>
    ),
    requests: (
      <>
        <path d="M4 5.75A2.75 2.75 0 0 1 6.75 3h10.5A2.75 2.75 0 0 1 20 5.75v7.5A2.75 2.75 0 0 1 17.25 16H11l-4.5 4v-4h-.75A2.75 2.75 0 0 1 3 13.25v-7.5Z" />
        <path d="M8 8h8M8 11.5h5" />
      </>
    ),
  }

  return (
    <svg
      aria-hidden="true"
      className="about-offering-icon"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {paths[name]}
    </svg>
  )
}

function SocialIcon({ platform }) {
  if (platform === 'LinkedIn') {
    return (
      <svg aria-hidden="true" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2ZM8.34 18H5.67V9.4h2.67ZM7 8.23a1.55 1.55 0 1 1 .02-3.1A1.55 1.55 0 0 1 7 8.23ZM18.34 18h-2.67v-4.18c0-1-.02-2.28-1.39-2.28-1.39 0-1.6 1.08-1.6 2.2V18h-2.67V9.4h2.56v1.18h.04a2.81 2.81 0 0 1 2.53-1.39c2.7 0 3.2 1.78 3.2 4.1Z" />
      </svg>
    )
  }

  return (
    <svg aria-hidden="true" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 .9a11.1 11.1 0 0 0-3.51 21.63c.55.1.76-.24.76-.54v-2.1c-3.1.67-3.75-1.32-3.75-1.32-.5-1.29-1.24-1.63-1.24-1.63-1.02-.7.08-.69.08-.69 1.12.08 1.71 1.15 1.71 1.15 1 .1.75 2.17 3.65 1.51.1-.73.39-1.23.7-1.51-2.48-.28-5.08-1.24-5.08-5.52 0-1.22.44-2.22 1.15-3-.12-.28-.5-1.42.11-2.96 0 0 .94-.3 3.06 1.15a10.65 10.65 0 0 1 5.57 0c2.12-1.45 3.06-1.15 3.06-1.15.61 1.54.23 2.68.11 2.96.72.78 1.15 1.78 1.15 3 0 4.29-2.6 5.23-5.09 5.51.4.35.75 1.03.75 2.08v3.08c0 .3.2.65.77.54A11.1 11.1 0 0 0 12 .9Z" />
    </svg>
  )
}

function AboutPage({ onNavigate }) {
  return (
    <main className="about-page-container">
      <header className="about-page-header">
        <div className="section-container">
          <p className="about-eyebrow">ABOUT THE PLATFORM</p>
          <h1 className="page-title">About U-NOTE</h1>
          <p className="page-subtitle">
            A shared space to find, access, and exchange academic study resources.
          </p>
        </div>
      </header>

      <section className="about-intro-section" aria-labelledby="about-intro-title">
        <div className="section-container about-intro-grid">
          <div>
            <h2 className="about-section-title" id="about-intro-title">About U-NOTE</h2>
            <p className="about-body-copy">
              U-NOTE is an academic notes and study resources sharing platform. It helps
              students access notes, PDFs, previous year papers, important questions, and
              other study materials, while making it easy to share resources peer to peer
              and request materials from the community.
            </p>
          </div>
          <aside className="about-mission-card">
            <h2 className="about-section-title">Our Mission</h2>
            <p className="about-body-copy">
              Our aim is to make academic resources easier for students to find, access,
              and share—so useful learning materials can reach the people who need them.
            </p>
          </aside>
        </div>
      </section>

      <section className="about-offerings-section" aria-labelledby="about-offerings-title">
        <div className="section-container">
          <div className="about-section-heading">
            <h2 className="about-section-title" id="about-offerings-title">What We Offer</h2>
            <p className="about-body-copy">
              The study materials and community features students can use on U-NOTE.
            </p>
          </div>
          <div className="about-offerings-grid">
            {offerings.map((offering) => (
              <article className="about-offering-card" key={offering.title}>
                <span className="about-offering-icon-wrap">
                  <OfferingIcon name={offering.icon} />
                </span>
                <h3>{offering.title}</h3>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="about-team-section" aria-labelledby="about-team-title">
        <div className="section-container">
          <div className="about-section-heading">
            <h2 className="about-section-title" id="about-team-title">Meet Our Team</h2>
          </div>
          <div className="about-team-grid">
            {teamMembers.map((member) => (
              <article className="about-team-card" key={member.name}>
                <div className="about-team-photo">
                  {member.photoUrl ? (
                    <img src={member.photoUrl} alt={`${member.name}`} />
                  ) : (
                    member.name
                      .split(' ')
                      .map((part) => part[0])
                      .join('')
                  )}
                </div>
                <h3>{member.name}</h3>
                <p className="about-team-role">{member.role}</p>
                <div className="about-team-socials">
                  {member.linkedinUrl && (
                    <a
                      href={member.linkedinUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      aria-label={`${member.name} on LinkedIn`}
                    >
                      <SocialIcon platform="LinkedIn" />
                    </a>
                  )}
                  {member.githubUrl && (
                    <a
                      href={member.githubUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      aria-label={`${member.name} on GitHub`}
                    >
                      <SocialIcon platform="GitHub" />
                    </a>
                  )}
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="about-feedback-section" aria-labelledby="about-feedback-title">
        <div className="section-container about-feedback-content">
          <div>
            <h2 className="about-section-title" id="about-feedback-title">Contact &amp; Feedback</h2>
            <p className="about-body-copy">
              Have a suggestion or feedback? We would love to hear how U-NOTE can better
              support your learning.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => onNavigate('/contact')}
          >
            Share Feedback
          </button>
        </div>
      </section>
    </main>
  )
}

export default AboutPage
