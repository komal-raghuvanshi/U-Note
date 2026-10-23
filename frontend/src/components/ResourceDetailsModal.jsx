function ResourceDetailsModal({ resource, onClose }) {
  if (!resource) return null;

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <button
          type="button"
          className="modal-close-icon"
          onClick={onClose}
          aria-label="Close modal"
        >
          &times;
        </button>

        <div className="modal-header">
          <span className="modal-type-badge">{resource.type}</span>
          <h2 className="modal-title">{resource.title}</h2>
        </div>

        <div className="modal-body">
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
              <span className="meta-value">{resource.subject}</span>
            </div>

            <div className="meta-item">
              <span className="meta-label">Unit</span>
              <span className="meta-value">
                {resource.unit_label || (resource.unit ? `Unit ${resource.unit}` : 'Not specified')}
              </span>
            </div>
          </div>

          <div className="modal-note-box">
            <p>
              This resource is part of the RGPV curriculum hierarchy. Additional features such as file downloading, rating, and teacher verification will connect to this card.
            </p>
          </div>
        </div>

        <div className="modal-footer" style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end', alignItems: 'center' }}>
          {resource.filename && (
            <a
              href={`http://127.0.0.1:5000/uploads/${resource.filename}`}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-secondary"
              style={{ textDecoration: 'none' }}
            >
              View PDF
            </a>
          )}
          <button type="button" className="btn btn-primary" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

export default ResourceDetailsModal;
