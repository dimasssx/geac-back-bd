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

    status         VARCHAR(20),
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
    event_id   UUID  REFERENCES events (id) ON DELETE CASCADE,
    status     BOOLEAN     DEFAULT FALSE,
    type       VARCHAR(25) DEFAULT 'REMINDER' CHECK (type IN ('REMINDER', 'SUBSCRIBE', 'CANCEL','APPROVED','REQUEST','REJECTED')),
    title      VARCHAR(255),
    message    TEXT,
    created_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE certificates
(
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id        UUID NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    validation_code VARCHAR(100) NOT NULL UNIQUE,
    issued_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE registrations
(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attended BOOLEAN DEFAULT FALSE,
    notified BOOLEAN DEFAULT FALSE,
    registration_date TIMESTAMP DEFAULT NOW(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id        UUID NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    UNIQUE(user_id, event_id)
);

CREATE TABLE evaluations
(
    id  SERIAL PRIMARY KEY,
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    rating INTEGER CHECK (rating>=1 AND rating <= 5),
    registration_id UUID NOT NULL REFERENCES registrations(id) ON DELETE CASCADE,
    UNIQUE(registration_id)
);

CREATE OR REPLACE VIEW vw_eventos_estatisticas AS
SELECT
    e.id AS event_id,
    e.title AS event_title,
    e.status AS event_status,
    COUNT(DISTINCT r.id) AS total_inscritos,
    SUM(CASE WHEN r.attended = TRUE THEN 1 ELSE 0 END) AS total_presentes,
    ROUND(AVG(ev.rating), 2) AS media_avaliacao
FROM events e
         LEFT JOIN registrations r ON e.id = r.event_id
         LEFT JOIN evaluations ev ON r.id = ev.registration_id
GROUP BY e.id, e.title, e.status;
-- ============================================================
-- USERS
-- ============================================================
INSERT INTO users (full_name, email, password_hash, user_type)
VALUES (
           'Administrador do Sistema',
           'admin@geac.com',
           '$2y$10$/5w0baJ/4H4MrN98n9Ika.T8mW8fOSJTr1MhKFp2E.QyPoh985ND2',
           'ADMIN'
       );
INSERT INTO users (full_name, email, password_hash, user_type) VALUES
                                                                   ('Ana Clara Silva','ana.silva@email.com','123456','STUDENT'),
                                                                   ('João Pedro Santos','joao.santos@email.com','123456','STUDENT'),
                                                                   ('Mariana Oliveira','mariana.oliveira@email.com','123456','STUDENT'),
                                                                   ('Carlos Eduardo Lima','carlos.lima@email.com','123456','PROFESSOR'),
                                                                   ('Fernanda Souza','fernanda.souza@email.com','123456','PROFESSOR'),
                                                                   ('Rafael Costa','rafael.costa@email.com','123456','STUDENT'),
                                                                   ('Beatriz Almeida','beatriz.almeida@email.com','123456','STUDENT'),
                                                                   ('Lucas Martins','lucas.martins@email.com','123456','STUDENT'),
                                                                   ('Juliana Ferreira','juliana.ferreira@email.com','123456','PROFESSOR'),
                                                                   ('Gabriel Rodrigues','gabriel.rodrigues@email.com','123456','STUDENT');

INSERT INTO users (full_name, email, password_hash, user_type)
SELECT
    'Aluno Teste ' || i,
    'aluno' || i || '@email.com',
    '123456',
    'STUDENT'
FROM generate_series(1,50) i;


-- ============================================================
-- CATEGORIES
-- ============================================================

INSERT INTO categories (name, description) VALUES
                                               ('Tecnologia','Eventos relacionados a tecnologia e inovação'),
                                               ('Saúde','Eventos da área da saúde'),
                                               ('Educação','Palestras e workshops educacionais'),
                                               ('Empreendedorismo','Eventos sobre startups e negócios'),
                                               ('Pesquisa Científica','Apresentação de pesquisas'),
                                               ('Extensão','Projetos de extensão universitária'),
                                               ('Engenharia','Eventos técnicos de engenharia'),
                                               ('Direito','Seminários jurídicos'),
                                               ('Sustentabilidade','Meio ambiente e impacto social'),
                                               ('Inteligência Artificial','IA e aprendizado de máquina');

INSERT INTO categories (name, description)
SELECT
    'Categoria Extra ' || i,
    'Categoria complementar acadêmica'
FROM generate_series(1,40) i;


-- ============================================================
-- LOCATIONS
-- ============================================================

INSERT INTO locations
(name, street, number, neighborhood, city, state, zip_code, campus, capacity)
VALUES
    ('Auditório Central','Rua Frei Caneca','100','Centro','Recife','PE','50000-000','Campus Recife',300),
    ('Bloco A - Sala 101','Av. Agamenon Magalhães','200','Boa Vista','Recife','PE','50050-000','Campus Recife',80),
    ('Auditório IFPE','Rua Henrique Dias','150','Centro','Caruaru','PE','55000-000','Campus Caruaru',250),
    ('Sala Multiuso','Rua Capitão João Velho','75','São José','Garanhuns','PE','55290-000','Campus Garanhuns',120),
    ('Auditório UFPE','Av. Prof. Moraes Rego','1235','Cidade Universitária','Recife','PE','50670-901','Campus UFPE',400);

INSERT INTO locations
(name, street, number, neighborhood, city, state, zip_code, campus, capacity)
SELECT
    'Sala Acadêmica ' || i,
    'Rua Acadêmica',
    i::text,
    'Centro',
    'Recife',
    'PE',
    '50000-000',
    'Campus Recife',
    60 + (i % 150)
FROM generate_series(1,45) i;


-- ============================================================
-- ORGANIZERS
-- ============================================================

INSERT INTO organizers (name, contact_email) VALUES
                                                 ('Centro Acadêmico de Computação','cac@universidade.br'),
                                                 ('Departamento de Engenharia','engenharia@universidade.br'),
                                                 ('Liga Acadêmica de IA','ligaia@universidade.br'),
                                                 ('Núcleo de Pesquisa Científica','npc@universidade.br'),
                                                 ('Empresa Júnior Tech','ejtech@universidade.br');

INSERT INTO organizers (name, contact_email)
SELECT
    'Organização Acadêmica ' || i,
    'org' || i || '@universidade.br'
FROM generate_series(1,45) i;


-- ============================================================
-- ORGANIZER_MEMBERS
-- ============================================================

INSERT INTO organizer_members (organizer_id, user_id)
SELECT
    o.id,
    u.id
FROM organizers o
         CROSS JOIN LATERAL (
    SELECT id
    FROM users
    ORDER BY random()
        LIMIT 3
) u
ON CONFLICT DO NOTHING;


-- ============================================================
-- SPEAKERS
-- ============================================================

INSERT INTO speakers (name, bio, email) VALUES
                                            ('Dr. Ricardo Mendes','Doutor em Ciência da Computação pela USP','ricardo.mendes@universidade.br'),
                                            ('Dra. Patrícia Gomes','Pesquisadora em Inteligência Artificial','patricia.gomes@universidade.br'),
                                            ('Dr. Eduardo Carvalho','Especialista em Engenharia de Software','eduardo.carvalho@universidade.br'),
                                            ('Dra. Camila Rocha','Pesquisadora em Sustentabilidade','camila.rocha@universidade.br'),
                                            ('Dr. Felipe Andrade','Especialista em Segurança da Informação','felipe.andrade@universidade.br');

INSERT INTO speakers (name, bio, email)
SELECT
    'Professor Convidado ' || i,
    'Especialista convidado para palestras acadêmicas',
    'prof' || i || '@universidade.br'
FROM generate_series(1,45) i;


-- ============================================================
-- TAGS
-- ============================================================

INSERT INTO tags (name)
SELECT 'Tag Acadêmica ' || i
FROM generate_series(1,50) i;


-- ============================================================
-- REQUIREMENTS
-- ============================================================

INSERT INTO requirements (description)
SELECT 'Requisito acadêmico ' || i
FROM generate_series(1,50) i;


-- ============================================================
-- EVENTS
-- ============================================================

INSERT INTO events
(organizer_id, category_id, location_id,
 title, description, start_time, end_time,
 workload_hours, max_capacity, status)
SELECT
    (SELECT id FROM organizers ORDER BY random() LIMIT 1),
    (SELECT id FROM categories ORDER BY random() LIMIT 1),
    (SELECT id FROM locations ORDER BY random() LIMIT 1),
    'Workshop de Desenvolvimento Web ' || i,
    'Evento prático com foco em aplicações reais e mercado.',
    NOW() + (i || ' days')::interval,
    NOW() + (i || ' days')::interval + interval '3 hours',
    3,
    150,
    CASE WHEN i % 2 = 0 THEN 'OPEN' ELSE 'CLOSED' END
FROM generate_series(1,50) i;


-- ============================================================
-- EVENT RELATIONSHIPS
-- ============================================================

INSERT INTO event_speakers (event_id, speaker_id)
SELECT e.id, s.id
FROM events e
         CROSS JOIN LATERAL (
    SELECT id FROM speakers ORDER BY random() LIMIT 2
) s
ON CONFLICT DO NOTHING;

INSERT INTO event_tags (event_id, tag_id)
SELECT e.id, t.id
FROM events e
         CROSS JOIN LATERAL (
    SELECT id FROM tags ORDER BY random() LIMIT 3
) t
ON CONFLICT DO NOTHING;

INSERT INTO event_requirements (event_id, requirement_id)
SELECT e.id, r.id
FROM events e
         CROSS JOIN LATERAL (
    SELECT id FROM requirements ORDER BY random() LIMIT 2
) r
ON CONFLICT DO NOTHING;


-- ============================================================
-- REGISTRATIONS
-- ============================================================

INSERT INTO registrations (user_id, event_id)
SELECT u.id, e.id
FROM users u
         JOIN events e ON random() < 0.2
    ON CONFLICT DO NOTHING;


-- ============================================================
-- NOTIFICATIONS
-- ============================================================

INSERT INTO notifications (user_id, event_id, type, title, message)
SELECT
    r.user_id,
    r.event_id,
    'SUBSCRIBE',
    'Inscrição Confirmada',
    'Sua inscrição foi realizada com sucesso.'
FROM registrations r
    LIMIT 100;


-- ============================================================
-- CERTIFICATES
-- ============================================================

INSERT INTO certificates (user_id, event_id, validation_code)
SELECT
    r.user_id,
    r.event_id,
    md5(random()::text)
FROM registrations r
    LIMIT 50;
-- ============================================================
-- MARCAR ALGUMAS INSCRIÇÕES COMO PARTICIPADAS
-- ============================================================

UPDATE registrations
SET attended = TRUE
WHERE random() < 0.5;


-- ============================================================
-- EVALUATIONS
-- ============================================================

INSERT INTO evaluations (comment, rating, registration_id)
SELECT
    CASE
        WHEN floor(random()*5)+1 = 5 THEN 'Evento excelente, superou expectativas.'
        WHEN floor(random()*5)+1 = 4 THEN 'Muito bom, agregou bastante conhecimento.'
        WHEN floor(random()*5)+1 = 3 THEN 'Evento bom, mas poderia ser mais dinâmico.'
        WHEN floor(random()*5)+1 = 2 THEN 'Conteúdo razoável, faltou organização.'
        ELSE 'Não atendeu totalmente às expectativas.'
        END,
    floor(random()*5)+1,
    r.id
FROM registrations r
WHERE r.attended = TRUE
    ON CONFLICT DO NOTHING;

