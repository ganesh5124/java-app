## Stage 1: Build Stage
FROM maven:3.8.8-eclipse-temurin-17 AS buildstage

# Set up working directory
WORKDIR /opt/app

# Copy only the necessary files to leverage Docker caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

# Build the Maven project
RUN mvn clean instal    l -DskipTests

## Stage 2: Tomcat Deploy Stage
FROM tomcat:9.0.94-jdk17-temurin-jammy

# Set up working directory
WORKDIR /usr/local/tomcat/webapps

# Copy the WAR file from the build stage to the Tomcat webapps directory
COPY --from=buildstage /opt/app/target/*.war .

# Rename the WAR file to ROOT.war to replace the default Tomcat application
RUN rm -rf ROOT && mv *.war ROOT.war

# Expose the Tomcat port
EXPOSE 8080

# Run Tomcat
CMD ["catalina.sh", "run"]
