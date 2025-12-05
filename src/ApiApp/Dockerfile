# Multi-stage Dockerfile for API Application
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["ApiApp.csproj", "."]
RUN dotnet restore "./ApiApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "ApiApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ApiApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ApiApp.dll"]