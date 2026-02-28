CREATE
EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE categories
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE locations
(
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    street          VARCHAR(150) NOT NULL,
    number          VARCHAR(20),
    neighborhood    VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(2)   NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL,
    campus          VARCHAR(100) NOT NULL,
    reference_point TEXT,
    capacity        INTEGER      NOT NULL
);

CREATE TABLE users
(
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type     VARCHAR(20),
    created_at    TIMESTAMP        DEFAULT NOW()
);

CREATE TABLE requirements
(
    id          SERIAL PRIMARY KEY,
    description VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE tags
(
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE speakers
(
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(150) NOT NULL,
    bio   TEXT,
    email VARCHAR(100)
);

CREATE TABLE speaker_qualifications
(
    id          SERIAL PRIMARY KEY,
    speaker_id  INTEGER      NOT NULL REFERENCES speakers (id) ON DELETE CASCADE,
    title_name  VARCHAR(100) NOT NULL, -- Ex: "Doutor em Ciência da Computação"
    institution VARCHAR(100) NOT NULL  -- Ex: "USP"
);

CREATE TABLE organizers
(
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100) NOT NULL UNIQUE,
    contact_email VARCHAR(100) NOT NULL
);

CREATE TABLE organizer_members
(
    id           SERIAL PRIMARY KEY,
    organizer_id UUID NOT NULL REFERENCES organizers (id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organizer_id, user_id)
);

CREATE TABLE events
(
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizer_id   UUID         NOT NULL REFERENCES organizers (id),
    category_id    INTEGER      NOT NULL REFERENCES categories (id),
    location_id    INTEGER REFERENCES locations (id),

    title          VARCHAR(200) NOT NULL,
    description    TEXT         NOT NULL,
    online_link    VARCHAR(255),

    start_time     TIMESTAMP    NOT NULL,
    end_time       TIMESTAMP    NOT NULL,
    workload_hours INTEGER      NOT NULL,
    max_capacity   INTEGER      NOT NULL,
--     requirement_id INTEGER              NOT NULL REFERENCES requirements (id), -- ✅ REMOVIDO: O relacionamento de requisitos agora é muitos-para-muitos, então essa coluna foi removida --- IGNORE ---

    status         VARCHAR(20)      DEFAULT 'UPCOMING' CHECK ( status IN
                                                               ('UPCOMING', 'ACTIVE', 'IN_PROGRESS', 'COMPLETED',
                                                                'CANCELLED') ),
    created_at     TIMESTAMP        DEFAULT NOW()
);

CREATE TABLE event_speakers
(
    event_id   UUID    NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    speaker_id INTEGER NOT NULL REFERENCES speakers (id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, speaker_id)
);

CREATE TABLE event_requirements
(
    event_id       UUID    NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    requirement_id INTEGER NOT NULL REFERENCES requirements (id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, requirement_id)
);


-- SÓ AGORA CRIAMOS EVENT_TAGS
CREATE TABLE event_tags
(
    event_id UUID    NOT NULL REFERENCES events (id),
    tag_id   INTEGER NOT NULL REFERENCES tags (id),
    PRIMARY KEY (event_id, tag_id)
);

CREATE TABLE organizer_requests
(
    id            SERIAL PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    organizer_id  UUID NOT NULL REFERENCES organizers (id) ON DELETE CASCADE,
    justification TEXT,
    status        VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    resolved_at   TIMESTAMP
);

CREATE TABLE notifications
(
    id         SERIAL PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id   UUID REFERENCES events (id) ON DELETE CASCADE,
    status     BOOLEAN     DEFAULT FALSE,
    type       VARCHAR(25) DEFAULT 'REMINDER' CHECK (type IN ('REMINDER', 'SUBSCRIBE', 'CANCEL', 'APPROVED', 'REQUEST',
                                                              'REJECTED')),
    title      VARCHAR(255),
    message    TEXT,
    created_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE certificates
(
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id        UUID         NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    validation_code VARCHAR(100) NOT NULL UNIQUE,
    issued_at       TIMESTAMP        DEFAULT NOW()
);

CREATE TABLE registrations
(
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attended          BOOLEAN          DEFAULT FALSE,
    notified          BOOLEAN          DEFAULT FALSE,
    registration_date TIMESTAMP        DEFAULT NOW(),
    user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id          UUID NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    UNIQUE (user_id, event_id)
);

CREATE TABLE evaluations
(
    id              SERIAL PRIMARY KEY,
    comment         TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    rating          INTEGER CHECK (rating >= 1 AND rating <= 5),
    registration_id UUID NOT NULL REFERENCES registrations (id) ON DELETE CASCADE,
    UNIQUE (registration_id)
);

CREATE
OR REPLACE VIEW vw_horas_extracurriculares_aluno AS
SELECT u.id                               AS student_id,
       u.full_name                        AS student_name,
       u.email                            AS student_email,
       COUNT(c.id)                        AS total_certificados_emitidos,
       COALESCE(SUM(e.workload_hours), 0) AS total_horas_acumuladas
FROM users u
         LEFT JOIN certificates c ON u.id = c.user_id
         LEFT JOIN events e ON c.event_id = e.id
WHERE u.user_type = 'STUDENT'
GROUP BY u.id, u.full_name, u.email;

CREATE
OR REPLACE VIEW vw_eventos_estatisticas AS
SELECT e.id                                               AS event_id,
       e.title                                            AS event_title,
       e.status                                           AS event_status,
       COUNT(DISTINCT r.id)                               AS total_inscritos,
       SUM(CASE WHEN r.attended = TRUE THEN 1 ELSE 0 END) AS total_presentes,
       ROUND(AVG(ev.rating), 2)                           AS media_avaliacao
FROM events e
         LEFT JOIN registrations r ON e.id = r.event_id
         LEFT JOIN evaluations ev ON r.id = ev.registration_id
GROUP BY e.id, e.title, e.status;

CREATE OR REPLACE VIEW vw_engajamento_organizacoes AS
SELECT
    o.id AS organizer_id,
    o.name AS organizer_name,
    COUNT(DISTINCT e.id) AS total_eventos_realizados,
    COALESCE(SUM(CASE WHEN r.attended = TRUE THEN 1 ELSE 0 END), 0) AS total_participantes_engajados
FROM organizers o
         LEFT JOIN events e ON o.id = e.organizer_id
         LEFT JOIN registrations r ON e.id = r.event_id
GROUP BY o.id, o.name;

INSERT INTO users (full_name, email, password_hash, user_type)
VALUES ('Administrador do Sistema',
        'admin@geac.com',
        '$2y$10$/5w0baJ/4H4MrN98n9Ika.T8mW8fOSJTr1MhKFp2E.QyPoh985ND2',
        'ADMIN');
-- 50 CATEGORIAS
INSERT INTO categories (name, description)
VALUES ('Programação Web', 'Desenvolvimento de sites e sistemas web.'),
       ('Saúde Coletiva', 'Estudos e práticas sobre saúde pública.'),
       ('Empreendedorismo', 'Inovação e novos modelos de negócio.'),
       ('Inteligência Artificial', 'Machine learning e redes neurais.'),
       ('Direito Civil', 'Debates sobre legislação e normas civis.'),
       ('Gestão de Projetos', 'Metodologias ágeis e tradicionais.'),
       ('Design de Experiência', 'Foco no usuário e interfaces.'),
       ('Engenharia de Software', 'Processos e qualidade de código.'),
       ('Marketing Digital', 'Estratégias para redes sociais e SEO.'),
       ('Finanças Pessoais', 'Educação financeira para estudantes.'),
       ('Cibersegurança', 'Proteção de dados e redes.'),
       ('Data Science', 'Análise de grandes volumes de dados.'),
       ('Arquitetura de Nuvem', 'AWS, Azure e Google Cloud.'),
       ('Desenvolvimento Mobile', 'Apps para Android e iOS.'),
       ('Soft Skills', 'Comunicação e liderança.'),
-- ... (repetir padrões para atingir 50)
       ('Robótica', 'Construção e programação de robôs.'),
       ('Educação Inclusiva', 'Métodos de ensino adaptados.'),
       ('Energias Renováveis', 'Sustentabilidade e energia solar.'),
       ('Psicologia Organizacional', 'Comportamento humano no trabalho.'),
       ('Bioinformática', 'Tecnologia aplicada à biologia.'),
       ('Blockchain', 'Criptoativos e contratos inteligentes.'),
       ('Internet das Coisas', 'Dispositivos conectados.'),
       ('Realidade Virtual', 'Imersão e simulações digitais.'),
       ('Ética na Tecnologia', 'Privacidade e viés algorítmico.'),
       ('Metodologias Ativas', 'Novas formas de aprender.'),
       ('Sustentabilidade Urbana', 'Cidades inteligentes e verdes.'),
       ('Logística e Supply Chain', 'Cadeia de suprimentos eficiente.'),
       ('Gastronomia Regional', 'Culinária do Nordeste brasileiro.'),
       ('História de Pernambuco', 'Raízes e cultura do estado.'),
       ('Literatura Brasileira', 'Clássicos e novos autores.'),
       ('Fotografia Digital', 'Técnicas de iluminação e edição.'),
       ('Produção Audiovisual', 'Criação de vídeos e podcasts.'),
       ('Gestão Pública', 'Administração de bens e serviços.'),
       ('Direito do Trabalho', 'Relações entre patrão e empregado.'),
       ('Contabilidade Geral', 'Balanços e demonstrações financeiras.'),
       ('Nutrição Esportiva', 'Dieta aplicada ao rendimento.'),
       ('Fisioterapia Preventiva', 'Exercícios para evitar lesões.'),
       ('Enfermagem Obstétrica', 'Cuidados no parto e pós-parto.'),
       ('Odontologia Social', 'Saúde bucal para comunidades.'),
       ('Agronomia Tropical', 'Cultivo em climas quentes.'),
       ('Medicina Veterinária', 'Cuidado com pequenos animais.'),
       ('Farmácia Clínica', 'Interações medicamentosas.'),
       ('Artes Visuais', 'Pintura, escultura e design.'),
       ('Música e Tecnologia', 'Produção fonográfica digital.'),
       ('Teatro e Expressão', 'Artes cênicas e comunicação.'),
       ('Astronomia Amadora', 'Observação dos astros.'),
       ('Física Quântica', 'Conceitos básicos e avançados.'),
       ('Química Industrial', 'Processos químicos em larga escala.'),
       ('Matemática Aplicada', 'Cálculos para engenharia.'),
       ('Sociologia Rural', 'Estudos do campo e sociedade.');

-- 50 REQUISITOS (EXEMPLOS)
INSERT INTO requirements (description)
SELECT 'Requisito de Conhecimento Nível ' || i
FROM generate_series(1, 50) i;

-- 50 TAGS
INSERT INTO tags (name)
VALUES ('#Java'),
       ('#Python'),
       ('#React'),
       ('#Medicina'),
       ('#Direito'),
       ('#UX'),
       ('#Agile'),
       ('#Cloud'),
       ('#DevOps'),
       ('#DataScience'),
       ('#Sprint'),
       ('#Inovação'),
       ('#RecifeTech'),
       ('#CaruaruNegocios'),
       ('#SurubimCriativo'),
       ('#Saude'),
       ('#Educação'),
       ('#Workshop'),
       ('#Hackathon'),
       ('#Palestra'),
       ('#BackEnd'),
       ('#FrontEnd'),
       ('#FullStack'),
       ('#Mobile'),
       ('#Security'),
       ('#AI'),
       ('#ML'),
       ('#BigData'),
       ('#IoT'),
       ('#Blockchain'),
       ('#Marketing'),
       ('#SEO'),
       ('#SocialMedia'),
       ('#Design'),
       ('#Figma'),
       ('#NodeJS'),
       ('#SQL'),
       ('#NoSQL'),
       ('#Docker'),
       ('#Kubernetes'),
       ('#Networking'),
       ('#SoftSkills'),
       ('#Leadership'),
       ('#Ethics'),
       ('#GreenTech'),
       ('#Fintech'),
       ('#EdTech'),
       ('#HealthTech'),
       ('#LegalTech'),
       ('#BioTech');

-- 50 USUÁRIOS (Alguns ADMIN, alguns STUDENT, alguns ORGANIZER)
INSERT INTO users (full_name, email, password_hash, user_type)
SELECT 'Usuário Exemplo ' || i,
       'usuario' || i || '@email.com',
       '$2a$10$8K1p/aP2Wq...', -- Hash fictício
       CASE WHEN i % 3 = 0 THEN 'ADMIN' WHEN i % 3 = 1 THEN 'STUDENT' ELSE 'ORGANIZER' END
FROM generate_series(1, 50) i;

-- 50 PALESTRANTES
INSERT INTO speakers (name, bio, email)
SELECT 'Palestrante ' || i,
       'Especialista com mais de 10 anos de experiência na área de atuação.',
       'speaker' || i || '@expert.com'
FROM generate_series(1, 50) i;

-- 50 ORGANIZADORES
INSERT INTO organizers (name, contact_email)
SELECT 'Centro Acadêmico de ' || c.name,
       'contato@organizador' || c.id || '.com'
FROM categories c LIMIT 50;

-- 50 LOCALIZAÇÕES (Distribuídas entre os campi do Enum)
INSERT INTO locations (name, street, number, neighborhood, city, state, zip_code, campus, capacity)
VALUES ('Auditório Principal Surubim', 'Rua João Batista', '100', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Central', 200),
       ('Laboratório de Informática A', 'Av. Agamenon Magalhães', '250', 'Maurício de Nassau', 'Caruaru', 'PE',
        '55012-000', 'Campus Caruaru Inovação', 40),
       ('Sala de Conferências Recife', 'Av. Boa Viagem', '1500', 'Boa Viagem', 'Recife', 'PE', '51020-000',
        'Campus Recife Alfa', 150),
       ('Bloco de Saúde Beta', 'Rua do Hospício', '50', 'Boa Vista', 'Recife', 'PE', '50060-000', 'Campus Recife Saúde',
        100),
       ('Espaço Criativo Delta', 'Rua Oscar Loureiro', '12', 'Coqueiral', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Criativo', 60),
-- ... (Gerando mais 45 variações baseadas no seu Enum)
       ('Auditório Sul Caruaru', 'Rua Josefa Taveira', '99', 'Salgado', 'Caruaru', 'PE', '55016-000',
        'Campus Caruaru Sul', 120),
       ('Sala de Pós-Graduação', 'Av. Caxangá', '2000', 'Caxangá', 'Recife', 'PE', '50711-000',
        'Campus Recife Pós-Graduação', 30),
       ('Centro de Convenções Norte', 'Rua da Aurora', '500', 'Santo Amaro', 'Recife', 'PE', '50040-000',
        'Campus Recife Norte', 500);
-- (Nota: Para completar 50, o ideal é rodar um loop ou replicar mudando o campus conforme sua lista de Enums)

-- Populando as demais 42 localizações automaticamente para garantir o volume:
INSERT INTO locations (name, street, number, neighborhood, city, state, zip_code, campus, capacity)
SELECT 'Sala ' || i,
       'Rua Exemplo ' || i,
       i * 2,
       'Bairro ' || i,
       CASE WHEN i % 3 = 0 THEN 'Recife' WHEN i % 3 = 1 THEN 'Caruaru' ELSE 'Surubim' END,
       'PE',
       '55000-000',
       (ARRAY['Campus Surubim Alfa', 'Campus Recife Beta', 'Campus Caruaru Central', 'Campus Surubim Inovação',
        'Campus Recife Saúde'])[floor(random()*5)+1],
    50
FROM generate_series(6, 50) i;


-- 50 EVENTOS
INSERT INTO events (organizer_id, category_id, location_id, title, description, start_time, end_time, workload_hours,
                    max_capacity, status)
SELECT (SELECT id FROM organizers OFFSET (i-1) LIMIT 1),
    (SELECT id FROM categories OFFSET (i-1) LIMIT 1),
    (SELECT id FROM locations OFFSET (i-1) LIMIT 1),
    'Evento de ' || (SELECT name FROM categories OFFSET (i-1) LIMIT 1),
    'Uma imersão completa sobre o tema, com foco em práticas de mercado e networking.',
    NOW() + (i || ' days')::interval,
    NOW() + (i || ' days 4 hours')::interval,
    4,
    (SELECT capacity FROM locations OFFSET (i-1) LIMIT 1),
    'UPCOMING'
FROM generate_series(1, 50) i;

-- 50 EVENT_SPEAKERS (Relacionando eventos aos palestrantes)
INSERT INTO event_speakers (event_id, speaker_id)
SELECT e.id, s.id
FROM (SELECT id FROM events LIMIT 50) e
         CROSS JOIN (SELECT id FROM speakers LIMIT 1) s;
-- Cada evento com ao menos 1 palestrante

-- 50 REGISTRATIONS (Inscrições de alunos nos eventos)
INSERT INTO registrations (user_id, event_id, registration_date)
SELECT (SELECT id FROM users WHERE user_type = 'STUDENT' LIMIT 1 OFFSET (i % 10)),
    (SELECT id FROM events LIMIT 1 OFFSET (i-1)),
    NOW()
FROM generate_series(1, 50) i;

-- 50 CERTIFICADOS
INSERT INTO certificates (user_id, event_id, validation_code)
SELECT r.user_id,
       r.event_id,
       'VALID-' || r.id
FROM registrations r LIMIT 50;

-- 50 AVALIAÇÕES
INSERT INTO evaluations (comment, rating, registration_id)
SELECT 'Excelente evento, muito proveitoso!',
       (floor(random() * 3) + 3), -- Notas entre 3 e 5
       r.id
FROM registrations r LIMIT 50;

-- 50 NOTIFICAÇÕES
INSERT INTO notifications (user_id, event_id, title, message, type)
SELECT u.id,
       (SELECT id FROM events LIMIT 1),
    'Lembrete de Evento',
    'Olá! Não esqueça que seu evento começa em breve.',
    'REMINDER'
FROM users u LIMIT 50;
