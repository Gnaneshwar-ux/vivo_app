import { useMemo, useState } from 'react'
import './login.css'

function isValidEmail(value) {
  // Pragmatic email check for UI validation (not RFC-complete).
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(true)
  const [touched, setTouched] = useState({ email: false, password: false })
  const [isSubmitting, setIsSubmitting] = useState(false)

  const emailError = useMemo(() => {
    if (!touched.email) return ''
    if (!email.trim()) return 'Email is required.'
    if (!isValidEmail(email.trim())) return 'Enter a valid email address.'
    return ''
  }, [email, touched.email])

  const passwordError = useMemo(() => {
    if (!touched.password) return ''
    if (!password) return 'Password is required.'
    if (password.length < 6) return 'Password must be at least 6 characters.'
    return ''
  }, [password, touched.password])

  const canSubmit = !emailError && !passwordError && email.trim() && password && !isSubmitting

  async function onSubmit(e) {
    e.preventDefault()
    setTouched({ email: true, password: true })
    if (!isValidEmail(email.trim()) || !password || password.length < 6) return

    // UI-only login (no backend yet). Simulate a request.
    setIsSubmitting(true)
    try {
      await new Promise((r) => setTimeout(r, 700))
      // eslint-disable-next-line no-alert
      alert(`Logged in as ${email.trim()}\nRemember me: ${rememberMe ? 'Yes' : 'No'}`)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="loginPage">
      <div className="loginShell" role="presentation">
        <div className="loginBrand" aria-hidden="false">
          <div className="brandMark" aria-hidden="true">
            <span className="brandMarkInner" />
          </div>
          <div>
            <div className="brandTitle">Vivo</div>
            <div className="brandSubtitle">Sign in to continue</div>
          </div>
        </div>

        <div className="loginCard" role="region" aria-label="Login form">
          <div className="cardHeader">
            <h1 className="cardTitle">Welcome back</h1>
            <p className="cardHint">Please enter your details to sign in.</p>
          </div>

          <form className="loginForm" onSubmit={onSubmit} noValidate>
            <div className="field">
              <label className="label" htmlFor="email">
                Email
              </label>
              <div className={`control ${emailError ? 'hasError' : ''}`}>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  inputMode="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  onBlur={() => setTouched((t) => ({ ...t, email: true }))}
                  aria-invalid={emailError ? 'true' : 'false'}
                  aria-describedby={emailError ? 'email-error' : undefined}
                />
              </div>
              {emailError ? (
                <div className="error" id="email-error">
                  {emailError}
                </div>
              ) : null}
            </div>

            <div className="field">
              <label className="label" htmlFor="password">
                Password
              </label>

              <div className={`control withSuffix ${passwordError ? 'hasError' : ''}`}>
                <input
                  id="password"
                  name="password"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  onBlur={() => setTouched((t) => ({ ...t, password: true }))}
                  aria-invalid={passwordError ? 'true' : 'false'}
                  aria-describedby={passwordError ? 'password-error' : undefined}
                />
                <button
                  className="suffixButton"
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
              {passwordError ? (
                <div className="error" id="password-error">
                  {passwordError}
                </div>
              ) : null}
            </div>

            <div className="row">
              <label className="checkbox">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                />
                <span>Remember me</span>
              </label>

              <a className="link" href="#" onClick={(e) => e.preventDefault()}>
                Forgot password?
              </a>
            </div>

            <button className="primaryButton" type="submit" disabled={!canSubmit}>
              {isSubmitting ? 'Signing in…' : 'Sign in'}
            </button>

            <div className="divider" role="separator" aria-label="or" />

            <button
              className="secondaryButton"
              type="button"
              onClick={() => {
                // eslint-disable-next-line no-alert
                alert('Demo: social login placeholder')
              }}
            >
              Continue with Google
            </button>

            <p className="footerText">
              Don’t have an account?{' '}
              <a className="link" href="#" onClick={(e) => e.preventDefault()}>
                Create one
              </a>
            </p>
          </form>
        </div>

        <p className="legal">© {new Date().getFullYear()} Vivo • All rights reserved</p>
      </div>
    </div>
  )
}
