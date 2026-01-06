pipeline {
  agent any

  environment {
    DOCKERHUB_USER = "fgonzalez8602"
    IMAGE_NAME     = "${env.DOCKERHUB_USER}/hello-ci-cd-devops"
    IMAGE_TAG      = "${env.BUILD_NUMBER}"
    TRIVY_IMAGE    = "aquasec/trivy:latest"
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
          echo Saving image to TAR for Trivy scan...
          docker save %IMAGE_NAME%:%IMAGE_TAG% -o image.tar

          echo Trivy scan (LOW,MEDIUM) - do not fail build...
          docker run --rm ^
            -v "%CD%:/work" ^
            %TRIVY_IMAGE% ^
            image --input /work/image.tar --severity LOW,MEDIUM --exit-code 0

          echo Trivy scan (HIGH,CRITICAL) - fail build if found...
          docker run --rm ^
            -v "%CD%:/work" ^
            %TRIVY_IMAGE% ^
            image --input /work/image.tar --severity HIGH,CRITICAL --exit-code 1
        """
      }
      post {
        always {
          // Limpieza del tar para no ensuciar el workspace (igual cleanWs lo borra)
          bat "if exist image.tar del /f /q image.tar"
        }
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
