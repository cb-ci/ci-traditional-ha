import jenkins.model.*
import hudson.security.*
import jenkins.security.*
import hudson.model.*
import java.io.File

def instance = Jenkins.getInstance()

println "--> Starting Admin User and Token Setup"

// 1. Set up Security to use Jenkins Internal Database
// This ensures the 'admin' user is actually stored in the internal realm
if (!(instance.getSecurityRealm() instanceof HudsonPrivateSecurityRealm)) {
    def hudsonRealm = new HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(hudsonRealm)
    
    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    instance.setAuthorizationStrategy(strategy)
    instance.save()
    println "--> Security Realm set to Jenkins Internal Database"
}

// 2. Create/Update Admin User (THE FIX)
def user = User.get("admin")
def password = "admin"

// We use 'Details.fromPlainPassword' to handle the hashing and security property
def securityRealmDetails = HudsonPrivateSecurityRealm.Details.fromPlainPassword(password)
user.addProperty(securityRealmDetails)
user.save()
println "--> Admin password set successfully"

// 3. Generate API Token
def apiTokenProperty = user.getProperty(ApiTokenProperty.class)
if (apiTokenProperty == null) {
    apiTokenProperty = new ApiTokenProperty()
    user.addProperty(apiTokenProperty)
}

// Remove old tokens with the same name to avoid duplicates
apiTokenProperty.tokenStore.getTokenListSortedByName().each { token ->
    if (token.name == "init-script-token") {
        apiTokenProperty.tokenStore.revokeToken(token.uuid)
    }
}

// Generate new token
def tokenResult = apiTokenProperty.tokenStore.generateNewToken("init-script-token")
user.save()

// 4. Write Token to File
def jenkinsHome = System.getenv("JENKINS_HOME") ?: instance.rootDir.absolutePath
def file = new File(jenkinsHome, "cjoc_token.txt")
file.text = tokenResult.plainValue

println "--> New Admin Token created and written to: ${file.absolutePath}"
println "--> New Admin Token : ${file.text}"
println "--> Script Complete"