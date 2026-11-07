import { useState, useEffect, useCallback } from 'react'
import { apiFetch } from '../api'

function formatRelativeTime(dateString) {
  if (!dateString) return ''
  try {
    const date = new Date(dateString)
    const now = new Date()
    const diffSec = Math.floor((now - date) / 1000)

    if (diffSec < 60) return 'Just now'
    if (diffSec < 3600) return `${Math.floor(diffSec / 60)}m ago`
    if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}h ago`
    if (diffSec < 604800) return `${Math.floor(diffSec / 86400)}d ago`
    return date.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })
  } catch {
    return ''
  }
}

function getNotificationIcon(type) {
  switch (type) {
    case 'resource_approved':
      return { icon: '✓', color: '#10b981', bg: '#d1fae5' }
    case 'resource_rejected':
      return { icon: '✕', color: '#ef4444', bg: '#fee2e2' }
    case 'resource_rated':
      return { icon: '★', color: '#f59e0b', bg: '#fef3c7' }
    case 'resource_verified':
      return { icon: '🛡️', color: '#6366f1', bg: '#e0e7ff' }
    case 'request_update':
      return { icon: '📋', color: '#0ea5e9', bg: '#e0f2fe' }
    case 'report_resolved':
      return { icon: '🚩', color: '#8b5cf6', bg: '#ede9fe' }
    case 'admin_alert':
      return { icon: '⚡', color: '#f97316', bg: '#ffedd5' }
    default:
      return { icon: '🔔', color: '#6366f1', bg: '#e0e7ff' }
  }
}

function NotificationsModal({ user, onClose, onNavigate, onUnreadCountChange }) {
  const [notifications, setNotifications] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [pushStatus, setPushStatus] = useState('default') // 'default', 'granted', 'denied', 'unsupported'
  const [pushSubscribed, setPushSubscribed] = useState(false)
  const [togglingPush, setTogglingPush] = useState(false)

  // Check Web Push support & permission
  useEffect(() => {
    if (!('Notification' in window) || !('serviceWorker' in navigator)) {
      setPushStatus('unsupported')
      return
    }
    setPushStatus(Notification.permission)
    if (Notification.permission === 'granted') {
      navigator.serviceWorker.ready.then((reg) => {
        reg.pushManager.getSubscription().then((sub) => {
          if (sub) setPushSubscribed(true)
        })
      }).catch(() => {})
    }
  }, [])

  const loadNotifications = useCallback(async () => {
    if (!user?.token) return
    setLoading(true)
    setError('')
    try {
      const res = await apiFetch('/notifications', {}, user.token)
      const data = await res.json()
      if (res.ok && data.success) {
        setNotifications(data.notifications || [])
        const unread = (data.notifications || []).filter((n) => !n.is_read).length
        if (onUnreadCountChange) onUnreadCountChange(unread)
      } else {
        setError(data.message || 'Unable to load notifications.')
      }
    } catch {
      setError('Network error while loading notifications.')
    } finally {
      setLoading(false)
    }
  }, [user, onUnreadCountChange])

  useEffect(() => {
    loadNotifications()
  }, [loadNotifications])

  const handleMarkAsRead = async (notifId, e) => {
    if (e) e.stopPropagation()
    try {
      await apiFetch(`/notifications/${notifId}/read`, { method: 'PUT' }, user.token)
      setNotifications((prev) =>
        prev.map((n) => (n.id === notifId ? { ...n, is_read: true } : n))
      )
      if (onUnreadCountChange) {
        onUnreadCountChange((prev) => Math.max(0, prev - 1))
      }
    } catch (err) {
      console.error('Failed to mark read:', err)
    }
  }

  const handleMarkAllRead = async () => {
    try {
      await apiFetch('/notifications/read-all', { method: 'PUT' }, user.token)
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })))
      if (onUnreadCountChange) onUnreadCountChange(0)
    } catch (err) {
      console.error('Failed to mark all read:', err)
    }
  }

  const handleDeleteNotification = async (notifId, e) => {
    if (e) e.stopPropagation()
    try {
      await apiFetch(`/notifications/${notifId}`, { method: 'DELETE' }, user.token)
      setNotifications((prev) => {
        const item = prev.find((n) => n.id === notifId)
        if (item && !item.is_read && onUnreadCountChange) {
          onUnreadCountChange((c) => Math.max(0, c - 1))
        }
        return prev.filter((n) => n.id !== notifId)
      })
    } catch (err) {
      console.error('Failed to delete notification:', err)
    }
  }

  const handleClearAll = async () => {
    if (!window.confirm('Are you sure you want to clear all notifications?')) return
    try {
      await apiFetch('/notifications', { method: 'DELETE' }, user.token)
      setNotifications([])
      if (onUnreadCountChange) onUnreadCountChange(0)
    } catch (err) {
      console.error('Failed to clear notifications:', err)
    }
  }

  const handleTogglePush = async () => {
    if (!('Notification' in window) || !('serviceWorker' in navigator)) {
      alert('Browser push notifications are not supported in this browser.')
      return
    }

    setTogglingPush(true)
    try {
      if (pushSubscribed) {
        // Unsubscribe
        const reg = await navigator.serviceWorker.ready
        const sub = await reg.pushManager.getSubscription()
        if (sub) {
          await apiFetch('/push/unsubscribe', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ endpoint: sub.endpoint })
          }, user.token)
          await sub.unsubscribe()
        }
        setPushSubscribed(false)
      } else {
        // Subscribe
        const permission = await Notification.requestPermission()
        setPushStatus(permission)
        if (permission !== 'granted') {
          alert('Notification permission was not granted.')
          return
        }

        const reg = await navigator.serviceWorker.register('/sw.js')
        await navigator.serviceWorker.ready

        // Check if application server key or dummy subscription can be created
        let sub = await reg.pushManager.getSubscription()
        if (!sub) {
          try {
            sub = await reg.pushManager.subscribe({
              userVisibleOnly: true,
              // Fallback application key if configured or standard
              applicationServerKey: 'BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBUYIHBQFLXYp5Nksh8U'
            })
          } catch {
            // Push service might fail in development/self-signed
            alert('Push service subscription could not be registered on this device.')
            return
          }
        }

        if (sub) {
          const rawKey = sub.getKey ? sub.getKey('p256dh') : null
          const rawAuth = sub.getKey ? sub.getKey('auth') : null
          const p256dh = rawKey ? btoa(String.fromCharCode.apply(null, new Uint8Array(rawKey))) : ''
          const auth = rawAuth ? btoa(String.fromCharCode.apply(null, new Uint8Array(rawAuth))) : ''

          await apiFetch('/push/subscribe', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              endpoint: sub.endpoint,
              keys: { p256dh, auth }
            })
          }, user.token)

          setPushSubscribed(true)
        }
      }
    } catch (err) {
      console.error('Push toggle error:', err)
      alert(err.message || 'Unable to update push notification settings.')
    } finally {
      setTogglingPush(false)
    }
  }

  const unreadCount = notifications.filter((n) => !n.is_read).length

  return (
    <div className="modal-overlay" onClick={onClose} role="dialog" aria-modal="true">
      <div className="modal-card notifications-modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '560px', maxHeight: '85vh', display: 'flex', flexDirection: 'column' }}>
        <button
          type="button"
          className="modal-close-icon"
          onClick={onClose}
          aria-label="Close modal"
        >
          &times;
        </button>

        {/* Modal Header */}
        <div className="modal-header" style={{ borderBottom: '1px solid #e2e8f0', paddingBottom: '0.85rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingRight: '2rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
              <h2 className="modal-title" style={{ margin: 0, fontSize: '1.25rem' }}>Notifications</h2>
              {unreadCount > 0 && (
                <span className="badge-unread-count" style={{ background: '#6366f1', color: '#fff', fontSize: '0.75rem', fontWeight: 700, padding: '0.15rem 0.55rem', borderRadius: '12px' }}>
                  {unreadCount} new
                </span>
              )}
            </div>

            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {unreadCount > 0 && (
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={handleMarkAllRead}
                  style={{ fontSize: '0.8rem', padding: '0.3rem 0.65rem' }}
                >
                  Mark all read
                </button>
              )}
              {notifications.length > 0 && (
                <button
                  type="button"
                  className="btn btn-outline"
                  onClick={handleClearAll}
                  style={{ fontSize: '0.8rem', padding: '0.3rem 0.65rem', color: '#ef4444', borderColor: '#fca5a5' }}
                >
                  Clear all
                </button>
              )}
            </div>
          </div>

          {/* Browser Push Toggle Banner */}
          {pushStatus !== 'unsupported' && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              background: '#f8fafc',
              border: '1px solid #e2e8f0',
              borderRadius: '8px',
              padding: '0.5rem 0.75rem',
              marginTop: '0.75rem',
              fontSize: '0.85rem'
            }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: '#475569' }}>
                <span>🔔</span> Desktop Push Alerts
              </span>
              <button
                type="button"
                className={`btn ${pushSubscribed ? 'btn-secondary' : 'btn-outline'}`}
                style={{ fontSize: '0.75rem', padding: '0.25rem 0.6rem' }}
                onClick={handleTogglePush}
                disabled={togglingPush}
              >
                {togglingPush ? 'Updating...' : pushSubscribed ? 'Turn Off' : 'Turn On'}
              </button>
            </div>
          )}
        </div>

        {/* Modal Body */}
        <div className="notifications-list-body" style={{ overflowY: 'auto', flex: 1, padding: '0.75rem 0' }}>
          {loading ? (
            <div style={{ textAlign: 'center', padding: '2.5rem 1rem', color: '#64748b' }}>
              <p>Loading notifications...</p>
            </div>
          ) : error ? (
            <div style={{ textAlign: 'center', padding: '2rem 1rem' }}>
              <p style={{ color: '#ef4444' }}>{error}</p>
              <button type="button" className="btn btn-secondary" onClick={loadNotifications} style={{ marginTop: '0.5rem', fontSize: '0.85rem' }}>
                Retry
              </button>
            </div>
          ) : notifications.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '3rem 1rem', color: '#94a3b8' }}>
              <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>🎉</div>
              <h3 style={{ fontSize: '1.05rem', color: '#475569', marginBottom: '0.25rem' }}>All caught up!</h3>
              <p style={{ fontSize: '0.875rem' }}>You do not have any new notifications at the moment.</p>
            </div>
          ) : (
            notifications.map((notif) => {
              const iconStyle = getNotificationIcon(notif.notification_type)
              return (
                <div
                  key={notif.id}
                  className={`notification-item ${notif.is_read ? 'notification-read' : 'notification-unread'}`}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '0.75rem',
                    padding: '0.85rem 1rem',
                    borderBottom: '1px solid #f1f5f9',
                    background: notif.is_read ? '#ffffff' : '#f8faff',
                    transition: 'background 0.15s ease',
                    position: 'relative'
                  }}
                  onClick={() => {
                    if (!notif.is_read) handleMarkAsRead(notif.id)
                    if (notif.related_resource_id && onNavigate) {
                      onClose()
                      onNavigate(`/resources`)
                    }
                  }}
                >
                  <div
                    style={{
                      width: '36px',
                      height: '36px',
                      borderRadius: '50%',
                      background: iconStyle.bg,
                      color: iconStyle.color,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '1rem',
                      fontWeight: 700,
                      flexShrink: 0
                    }}
                  >
                    {iconStyle.icon}
                  </div>

                  <div style={{ flex: 1, minWidth: 0, paddingRight: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.2rem' }}>
                      <strong style={{ fontSize: '0.92rem', color: notif.is_read ? '#334155' : '#0f172a' }}>
                        {notif.title}
                      </strong>
                      {!notif.is_read && (
                        <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#6366f1', display: 'inline-block' }} />
                      )}
                    </div>
                    <p style={{ margin: 0, fontSize: '0.85rem', color: '#475569', lineHeight: 1.4 }}>
                      {notif.message}
                    </p>
                    <span style={{ fontSize: '0.75rem', color: '#94a3b8', display: 'block', marginTop: '0.35rem' }}>
                      {formatRelativeTime(notif.created_at)}
                    </span>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', alignItems: 'flex-end', flexShrink: 0 }}>
                    {!notif.is_read && (
                      <button
                        type="button"
                        title="Mark as read"
                        onClick={(e) => handleMarkAsRead(notif.id, e)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#6366f1', fontSize: '0.8rem', padding: '0.2rem' }}
                      >
                        ✓
                      </button>
                    )}
                    <button
                      type="button"
                      title="Delete notification"
                      onClick={(e) => handleDeleteNotification(notif.id, e)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8', fontSize: '0.85rem', padding: '0.2rem' }}
                    >
                      &times;
                    </button>
                  </div>
                </div>
              )
            })
          )}
        </div>

        {/* Modal Footer */}
        <div className="modal-footer" style={{ borderTop: '1px solid #e2e8f0', paddingTop: '0.75rem', display: 'flex', justifyContent: 'flex-end' }}>
          <button type="button" className="btn btn-primary" onClick={onClose} style={{ fontSize: '0.9rem', padding: '0.45rem 1.25rem' }}>
            Done
          </button>
        </div>
      </div>
    </div>
  )
}

export default NotificationsModal
