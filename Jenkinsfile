pipeline {
    // Esegui sull'agent con questa label (definita nel JCasC del controller).
    agent { label 'build' }

    environment {
        // Coordinate dell'immagine su Docker Hub.
        DOCKERHUB_USER = 'namanari36'
        IMAGE_REPO     = 'formazione_sou'
        IMAGE_NAME     = "${DOCKERHUB_USER}/${IMAGE_REPO}"
        // ID della credential creata a mano nella UI di Jenkins.
        DOCKERHUB_CREDS = 'dockerhub-credentials'
        // Socket Podman dell'host montato nell'agent (DooD).
        CONTAINER_HOST = 'unix:///run/podman/podman.sock'
    }

    stages {
        stage('Determina il tag immagine') {
            steps {
                script {
                    // Logica di tagging richiesta dalla traccia.
                    // ATTENZIONE all'ordine: quando si builda da un tag git,
                    // sia TAG_NAME sia BRANCH_NAME valgono il nome del tag,
                    // quindi il caso "tag" va controllato PER PRIMO.
                    if (env.TAG_NAME) {
                        // Buildato da tag git -> immagine = stesso tag git.
                        env.IMAGE_TAG = env.TAG_NAME
                    } else if (env.BRANCH_NAME == 'main') {
                        // Buildato da master -> latest.
                        env.IMAGE_TAG = 'latest'
                    } else if (env.BRANCH_NAME == 'develop') {
                        // Buildato da develop -> develop-<SHA commit>.
                        // GIT_COMMIT è il SHA completo; lo accorciamo a 7 char.
                        env.IMAGE_TAG = "develop-${env.GIT_COMMIT.take(7)}"
                    } else {
                        // Altri branch: tag derivato dal nome branch (sanitizzato).
                        env.IMAGE_TAG = env.BRANCH_NAME.replaceAll('[^a-zA-Z0-9_.-]', '-')
                    }
                    echo "Immagine: ${IMAGE_NAME}:${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build immagine') {
            steps {
                // Build via socket Podman dell'host (DooD).
                sh '''
                    podman --remote build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -f Dockerfile .
                '''
            }
        }

        stage('Push su Docker Hub') {
            steps {
                // Inietta username/token dalla credential, senza esporli nei log.
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDS}",
                    usernameVariable: 'REG_USER',
                    passwordVariable: 'REG_PASS'
                )]) {
                    sh '''
                        echo "${REG_PASS}" | podman --remote login docker.io \
                            -u "${REG_USER}" --password-stdin
                        podman --remote push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }

    post {
        always {
            // Logout pulito dal registry.
            sh 'podman --remote logout docker.io || true'
        }
    }
}