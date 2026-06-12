import Foundation
import Testing
@testable import MeowPlannerCore

@Suite("Account authentication")
struct AccountAuthenticationTests {
    @Test("email account registration normalizes email and signs in with the same password")
    func emailRegistrationNormalizesEmailAndSignsIn() throws {
        var authenticator = EmailAccountAuthenticator()
        let now = Date(timeIntervalSince1970: 1_800)

        let registered = try authenticator.register(
            email: "  Yueling.Qiu@Example.COM ",
            password: "meowplanner-2026",
            now: now
        )

        #expect(registered.provider == .email)
        #expect(registered.emailAddress == "yueling.qiu@example.com")
        #expect(registered.displayName == "Yueling.Qiu")
        #expect(registered.lastSignedInAt == now)

        let signedIn = try authenticator.signIn(
            email: "yueling.qiu@example.com",
            password: "meowplanner-2026",
            now: Date(timeIntervalSince1970: 2_400)
        )

        #expect(signedIn.id == registered.id)
        #expect(signedIn.emailAddress == registered.emailAddress)
        #expect(signedIn.lastSignedInAt == Date(timeIntervalSince1970: 2_400))
    }

    @Test("email registration rejects invalid email and weak passwords")
    func emailRegistrationRejectsInvalidInput() {
        var authenticator = EmailAccountAuthenticator()

        #expect(throws: AccountAuthenticationError.invalidEmail) {
            try authenticator.register(email: "not-an-email", password: "meowplanner-2026")
        }

        #expect(throws: AccountAuthenticationError.weakPassword(minimumCharacters: 8)) {
            try authenticator.register(email: "cat@example.com", password: "short")
        }
    }

    @Test("email registration rejects duplicate accounts")
    func emailRegistrationRejectsDuplicates() throws {
        var authenticator = EmailAccountAuthenticator()
        _ = try authenticator.register(email: "cat@example.com", password: "meowplanner-2026")

        #expect(throws: AccountAuthenticationError.accountAlreadyExists) {
            try authenticator.register(email: " CAT@example.com ", password: "another-password")
        }
    }

    @Test("email sign in distinguishes unknown accounts from incorrect passwords")
    func emailSignInReportsExpectedFailures() throws {
        var authenticator = EmailAccountAuthenticator()
        _ = try authenticator.register(email: "cat@example.com", password: "meowplanner-2026")

        #expect(throws: AccountAuthenticationError.accountNotFound) {
            try authenticator.signIn(email: "missing@example.com", password: "meowplanner-2026")
        }

        #expect(throws: AccountAuthenticationError.incorrectPassword) {
            try authenticator.signIn(email: "cat@example.com", password: "wrong-password")
        }
    }

    @Test("Apple account profiles preserve the stable Apple user identifier")
    func appleProfilesPreserveStableIdentifier() {
        let profile = AccountProfile.apple(
            userIdentifier: "001122.abcdef",
            emailAddress: "private@example.com",
            displayName: "Yueling Qiu",
            now: Date(timeIntervalSince1970: 3_600)
        )

        #expect(profile.id == "apple:001122.abcdef")
        #expect(profile.provider == .apple)
        #expect(profile.emailAddress == "private@example.com")
        #expect(profile.displayName == "Yueling Qiu")
    }

    @Test("Firebase email account profiles preserve the stable cloud user identifier")
    func firebaseEmailProfilePreservesUserIdentifier() {
        let profile = AccountProfile.firebaseEmail(
            userID: "firebase-user-123",
            emailAddress: "  CAT@Example.COM ",
            displayName: "  FuFu  "
        )

        #expect(profile.id == "firebase:firebase-user-123")
        #expect(profile.provider == .email)
        #expect(profile.remoteUserID == "firebase-user-123")
        #expect(profile.emailAddress == "cat@example.com")
        #expect(profile.displayName == "FuFu")
    }
}
