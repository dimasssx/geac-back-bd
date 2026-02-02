📅 Sistema de Gestão de Eventos Universitários
---


👥 Integrantes
---

  Dimas Celestino - Desenvolvedor(a)
  
  José Portela - Desenvolvedor(a)
  
  Julio Neto - Desenvolvedor(a)
  
  Pedro Tobias - Desenvolvedor(a)

<br>
  
📃 Sobre o Projeto
---

  Este projeto consiste na implementação de uma plataforma completa para Gestão de Eventos Universitários, desenvolvido como requisito avaliativo para a disciplina de Engenharia de Software, ministrada pela Professora Thaís Alves Burity Rocha na UFAPE (Universidade Federal do Agreste de Pernambuco).
  
  O objetivo é criar um ecossistema que centralize a divulgação, organização e inscrição em eventos acadêmicos, conectando departamentos, centros acadêmicos e grupos estudantis com a comunidade universitária (alunos e professores). A plataforma resolve o problema da       fragmentação de informações, facilitando o acesso à cultura e conhecimento complementar.
  
<br>

📍 Objetivos e Funcionalidades
---

  O sistema visa aumentar a visibilidade das atividades acadêmicas e simplificar a burocracia de gestão. As principais funcionalidades incluem:

<br>
  
🎓 Para Organizadores (Departamentos/C.A.s):
---

  - Cadastro detalhado de eventos (palestras, seminários, feiras, festivais).
  
  - Definição de cronograma, palestrantes, local e requisitos.
  
  - Gerenciamento de inscritos e lista de presença.
  
  - Emissão automática de certificados de participação.
  
  - Coleta de feedback pós-evento para melhoria contínua.
    
<br>

🙋‍♂️ Para Participantes (Alunos/Professores):
---

  - Busca avançada de eventos por categoria, data, campus ou palavras-chave.
  
  - Inscrição rápida e facilitada.
  
  - Acesso ao histórico de participações e certificados.

<br>

🛠️ Tecnologias Utilizadas
---

O projeto é construído utilizando uma arquitetura moderna, separando o Back-end (API Rest) do Front-end.

Back-end (API)
  
  - Java 25 (Preview/Latest Features)
  
  - Spring Boot - Framework base para a aplicação.
  
  - Spring Security - Para autenticação e autorização.
  
  - JPA / Hibernate - Persistência de dados.

Front-end (Cliente Web)
  
  - React - Biblioteca para construção de interfaces.
  
  - Next.js - Framework React para produção.
  
  - Tailwind CSS - Para estilização.

Ferramentas & DevOps
  
  - Git & GitHub - Versionamento de código.
  
  - Docker - Containerização dos serviços.
  
  - PostgreSQL - Banco de dados relacional.

<br>
  
🚀 Como Executar o Projeto
---

  Pré-requisitos
  
  - Java JDK 25 instalado.
  
  - Node.js (versão LTS ou superior).
  
  - Docker (Opcional, mas recomendado para o Banco de Dados).

  Passos:

  1. Clone o repositório:
     
         git clone https://github.com/GestaoDeEventosAcademicosECulturais/geac.git

 2. Back-end:

        cd backend
        ./mvnw spring-boot:run

3. Front-end:

        cd frontend
        npm install
        npm run dev

4: Acesse a aplicação em http://localhost:3000
