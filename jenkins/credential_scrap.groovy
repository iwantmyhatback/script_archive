// Credential Getter Script

import com.cloudbees.plugins.credentials.CredentialsMatchers
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.IdCredentials
import com.cloudbees.plugins.credentials.domains.DomainRequirement
import hudson.security.ACL
import jenkins.model.Jenkins
import com.cloudbees.hudson.plugins.folder.Folder
import org.jenkinsci.plugins.plaincredentials.FileCredentials
import java.util.Collections

// Set the folder name to null for system-level credentials
String folderName = null 
String credentialId = "RANDOM_CREDENTIAL_ID"

// Function to look up credentials by folder name and ID
IdCredentials lookupCredentials(String folderName, String credentialsId) {
    Jenkins jenkins = Jenkins.get()
    def context = folderName ? jenkins.getItemByFullName(folderName, Folder.class) : jenkins

    if (!context) {
        println "Context not found: $folderName"
        return null
    }

    return CredentialsMatchers.firstOrNull(
        CredentialsProvider.lookupCredentials(
            IdCredentials.class,
            context,
            ACL.SYSTEM,
            Collections.<DomainRequirement>emptyList()
        ),
        CredentialsMatchers.withId(credentialsId)
    )
}

// Main execution
IdCredentials credential = lookupCredentials(folderName, credentialId)

if (credential) {
    println "Credential type: ${credential.class.simpleName}"

    if (credential instanceof FileCredentials) {
        FileCredentials fileCredential = (FileCredentials) credential
        println "File Name: ${fileCredential.fileName}"
        println "File Content: ${fileCredential.content.text}"
    }

    if (credential.metaClass.respondsTo(credential, "getUsername")) {
        String user = credential.getUsername()
        println "User: ${user}"
    }

    if (credential.metaClass.respondsTo(credential, "getPassword")) {
        String password = credential.getPassword().getPlainText()
        println "Password: ${password}"
    }

    if (credential.metaClass.respondsTo(credential, "getSecret")) {
        String secret = credential.getSecret()
        println "Secret: ${secret}"
    }

    if (credential.metaClass.respondsTo(credential, "getDescription")) {
        String description = credential.getDescription()
        println "Description: ${description}"
    }

    if (credential.metaClass.respondsTo(credential, "getPassphrase")) {
        String passphrase = credential.getPassphrase()
        println "Passphrase: ${passphrase}"
    }

    if (credential.metaClass.respondsTo(credential, "getPrivateKeys")) {
        def privateKeys = credential.getPrivateKeys() // Type depends on implementation
        println "Private Key(s): ${privateKeys}"
    }

    if (credential.metaClass.respondsTo(credential, "getPrivateKeySource")) {
        def privateKeySource = credential.getPrivateKeySource() // Type depends on implementation
        println "Private Key Source: ${privateKeySource}"
    }
} else {
    println "Credential ID Not Found"
}
