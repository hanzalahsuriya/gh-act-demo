# Use the official .NET 9 SDK to build the app
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app

# Copy project files
COPY . ./

# Restore dependencies and publish
RUN dotnet restore ./DemoApi
RUN dotnet publish ./DemoApi -c Release -o out

# Use the .NET 9 runtime image
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app

# Copy the built app from the previous stage
COPY --from=build /app/out .

# Expose ports
EXPOSE 80
EXPOSE 443

# Start the application
CMD ["dotnet", "DemoApi.dll"]
