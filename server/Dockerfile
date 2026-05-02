FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY *.csproj .
RUN dotnet restore server.csproj

COPY . .
RUN dotnet publish -c Release -o /app

ENV ASPNETCORE_ENVIRONMENT=Production

RUN mkdir -p /app/db
RUN touch /app/db/zest.db

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .

ENV ASPNETCORE_URLS=http://0.0.0.0:10000

EXPOSE 10000

ENTRYPOINT ["dotnet", "server.dll"] 
