pipeline {
  agent any

  environment {
    DOCKERHUB_USER = "fgonzalez8602"
    IMAGE_NAME     = "${env.DOCKERHUB_USER}/hello-ci-cd-devops"
    IMAGE_TAG      = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install and Test') {
      steps {
        bat """
          python -m venv .venv
          call .venv\\Scripts\\activate
          python -m pip install --upgrade pip
          python -m pip install -r requirements.txt
          python -m pytest --cov=app --cov-report=xml
        """
      }
      post {
        always {
          archiveArtifacts artifacts: 'coverage.xml', onlyIfSuccessful: false
        }
      }
    }

    stage('SonarCloud Analysis') {
      steps {
        withCredentials([string(credentialsId: 'sonarcloud-token', variable: 'SONAR_TOKEN')]) {
          bat """
            docker run --rm ^
              -e SONAR_TOKEN=%SONAR_TOKEN% ^
              -v "%CD%:/usr/src" ^
              sonarsource/sonar-scanner-cli:latest
          """
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        bat """
          docker build -t %IMAGE_NAME%:%IMAGE_TAG% .
          docker tag %IMAGE_NAME%:%IMAGE_TAG% %IMAGE_NAME%:latest
        """
      }
    }

    stage('Trivy Scan') {
      steps {
        bat """
          docker run --rm aquasec/trivy:latest image --exit-code 0 --severity LOW,MEDIUM %IMAGE_NAME%:%IMAGE_TAG%
          docker run --rm aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL %IMAGE_NAME%:%IMAGE_TAG%
        """
      }
    }

    stage('Push to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          bat """
            echo %DH_PASS% | docker login -u %DH_USER% --password-stdin
            docker push %IMAGE_NAME%:%IMAGE_TAG%
            docker push %IMAGE_NAME%:latest
          """
        }
      }
    }
  }

  post {
    always {
      bat "docker logout"
      cleanWs()
    }
  }
}
