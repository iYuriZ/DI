<?php
    require_once 'app/database.php';

    if(!isset($_GET['passagiernummer']) || !isset($_GET['vluchtnummer']) || !isset($_GET['balienummer'])) {
        exit;
    }

    // Gegevens van passagier opzoeken
    $db = connectDatabase();
    $stmt = $db->prepare('SELECT *
                            FROM
                                Passagier p INNER JOIN PassagierVoorVlucht pvv
                                ON pvv.passagiernummer = p.passagiernummer
                            WHERE
                                p.passagiernummer = ?');
    $stmt->execute([
        $_GET['passagiernummer']
    ]);
    $passagier = $stmt->fetch();

    // Bagage van passagier vragen
    $stmt = $db->prepare('SELECT * FROM Object WHERE passagiernummer = ? AND vluchtnummer = ?');
    $stmt->execute([
        $_GET['passagiernummer'],
        $_GET['vluchtnummer']
    ]);

    $bagage = [];

    while($row = $stmt->fetch()) {
        array_push($bagage, $row);
    }
?>

<!doctype html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Home</title>
    <link rel="stylesheet" href="CSS/Style.css">
    <link rel="stylesheet" href="CSS/bootstrap.css">
</head>

<body>

<div class="row main-container">
    <div class="col-md-4"></div>

    <main class="col-md-4">
        <h1><?= $passagier['naam'] ?></h1>
        <p>Check <?= $passagier['naam'] ?> in.</p>

        <form method="POST" action="/app/passagier-update.php?balienummer=<?= $_GET['balienummer'] ?>&vluchtnummer=<?= $_GET['vluchtnummer'] ?>&passagiernummer=<?= $_GET['passagiernummer'] ?>">
            <div class="form-group">
                <label>Stoelnummer</label>
                <input type="text" class="form-control" name="chair" value="<?= $passagier['stoel'] ?>"/>
            </div>

            <div class="form-group">
                <label>Inchecktijdstip</label>
                <input type="text" class="form-control" name="checkintime" value="<?= $passagier['inchecktijdstip'] ?>"/>
            </div>

            <button class="btn btn-success">Passagier inchecken</button>
        </form>
        
        <hr>

        <!-- Bagage -->
        <h3>Bagage</h3>

        <?php if (count($bagage) > 0) : ?>
            <table class="table table-bordered table-striped table-hover">
                <thead>
                    <th>Volgnummer</th>
                    <th>Gewicht (in KG)</th>
                    <th></th>
                </thead>
                <tbody>
                    <?php foreach($bagage as $bagageObject): ?>
                        <tr>
                            <td>
                                <?= $bagageObject['volgnummer'] ?>
                            </td>
                            <td>
                                <?= $bagageObject['gewicht'] ?>
                            </td>
                            <td>
                                <a href="/app/bagage-verwijderen.php?balienummer=<?= $_GET['balienummer'] ?>&vluchtnummer=<?= $_GET['vluchtnummer'] ?>&passagiernummer=<?= $_GET['passagiernummer'] ?>&objectnummer=<?= $bagageObject['volgnummer'] ?>" class="btn btn-warning">Verwijderen</a>
                            </td>
                        </td>
                    <?php endforeach; ?>
                </tbody>
            </table>
        <?php else: ?>
            <p><b>Geen bagage gevonden</b></p>
        <?php endif; ?>

        <hr>

        <h4>Bagage toevoegen</h4>

        <?php if(isset($_GET['bagage_error']) && $_GET['bagage_error'] != ''): ?>
            <div class="alert alert-danger">
                <?= $_GET['bagage_error'] ?>
            </div>
        <?php endif; ?>

        <form class="form-group" method="post" action="/app/bagage-toevoegen.php?balienummer=<?= $_GET['balienummer'] ?>&vluchtnummer=<?= $_GET['vluchtnummer'] ?>&passagiernummer=<?= $_GET['passagiernummer'] ?>">
            <div class="form-group">
                <input type="text" class="form-control" name="gewicht" placeholder="Gewicht"/>
                <br>
                <button class="btn btn-success">Toevoegen</button>
            </div>
        </form>

        <hr>

    </main>

    <div class="col-md-4"></div>
</div>

</body>

</html>
