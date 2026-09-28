#!/usr/bin/env bash
# Seeds a Kotlin project whose feature branch adds Foo.card(); Foo.kt:88 dereferences a nullable profile with `!!`.
set -euo pipefail

mkdir -p src/main/kotlin/profiles

cat > Foo.kt.full <<'KT'
package profiles

import java.time.Instant

data class Profile(
    val id: String,
    val displayName: String,
    val email: String?,
    val lastSeen: Instant?,
    val teamId: String?,
    val avatarUrl: String?,
)

data class Team(
    val id: String,
    val name: String,
    val ownerId: String,
)

data class ProfileCard(
    val title: String,
    val subtitle: String,
    val contact: String,
)

interface ProfileStore {
    fun byId(id: String): Profile?
    fun all(): List<Profile>
}

interface TeamStore {
    fun byId(id: String): Team?
}

class Foo(
    private val profiles: ProfileStore,
    private val teams: TeamStore,
    private val now: () -> Instant = Instant::now,
) {
    fun displayName(profileId: String): String =
        profiles.byId(profileId)?.displayName ?: "Unknown user"

    fun contact(profileId: String): String {
        val profile = profiles.byId(profileId) ?: return "-"
        return profile.email ?: "no email on file"
    }

    fun isActive(profileId: String, windowSeconds: Long): Boolean {
        val lastSeen = profiles.byId(profileId)?.lastSeen ?: return false
        return lastSeen.isAfter(now().minusSeconds(windowSeconds))
    }

    fun activeProfiles(windowSeconds: Long): List<Profile> =
        profiles.all().filter { profile ->
            val lastSeen = profile.lastSeen
            lastSeen != null && lastSeen.isAfter(now().minusSeconds(windowSeconds))
        }

    fun teamName(profileId: String): String {
        val teamId = profiles.byId(profileId)?.teamId ?: return "No team"
        return teams.byId(teamId)?.name ?: "No team"
    }

    fun isTeamOwner(profileId: String): Boolean {
        val teamId = profiles.byId(profileId)?.teamId ?: return false
        return teams.byId(teamId)?.ownerId == profileId
    }

    fun searchByName(query: String): List<Profile> {
        if (query.isBlank()) return emptyList()
        val needle = query.trim().lowercase()
        return profiles.all().filter { it.displayName.lowercase().contains(needle) }
    }

    fun initials(profileId: String): String {
        val name = profiles.byId(profileId)?.displayName ?: return "?"
        return name.split(" ")
            .filter { it.isNotBlank() }
            .take(2)
            .joinToString("") { it.first().uppercase() }
    }

    // Builds the card shown in the team sidebar for any profile id in a shared link.
    fun card(profileId: String): ProfileCard {
        val profile = profiles.byId(profileId)
        val team = profile?.teamId?.let { teams.byId(it) }
        return ProfileCard(
            title = profile!!.displayName,
            subtitle = team?.name ?: "No team",
            contact = profile.email ?: "no email on file",
        )
    }
}
KT

# main ends after initials(); the branch adds card().
{ head -n 81 Foo.kt.full; echo "}"; } > src/main/kotlin/profiles/Foo.kt

git init -q -b main
git add src
git -c user.email=eval@example.com -c user.name=eval commit -qm "Add profile lookups"
git checkout -qb feature/profile-card
mv Foo.kt.full src/main/kotlin/profiles/Foo.kt
git -c user.email=eval@example.com -c user.name=eval commit -qam "Add profile card for shared links"
